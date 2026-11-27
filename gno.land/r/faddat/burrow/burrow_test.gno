package burrow

import (
	"strconv"
	"strings"
	"testing"
	"time"
)

const (
	alice address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"
	bob   address = "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
	carol address = "g1skl80cuz8zq3lul9pgz5pc35l2pfzgxgfpsqkx"
)

func bump(blocks int64) {
	ctx := testing.GetContext()
	testing.SetHeight(ctx.Height + blocks)
}

func mustPanic(t *testing.T, want string, fn func()) {
	rec := revive(fn)
	if rec == nil {
		t.Fatalf("expected panic %q", want)
	}
	msg, ok := rec.(string)
	if !ok {
		t.Fatalf("panic type %T (%v), want %q", rec, rec, want)
	}
	if !strings.Contains(msg, want) {
		t.Fatalf("panic %q does not contain %q", msg, want)
	}
}

func TestSubmitVoteAndKarma(cur realm, t *testing.T) {
	boot()
	testing.SetOriginCaller(alice)
	id := Submit(cross(cur), "  Hello burrow  ", "https://Example.com/a/", "a note")
	if id != 1 {
		t.Fatalf("id %d", id)
	}
	if items[id].Title != "Hello burrow" {
		t.Fatalf("title %q", items[id].Title)
	}
	if items[id].URL != "https://example.com/a" {
		t.Fatalf("url %q", items[id].URL)
	}
	if items[id].CreatedUnix != time.Now().Unix() {
		t.Fatalf("created %d now %d", items[id].CreatedUnix, time.Now().Unix())
	}
	if items[id].CreatedHeight != testing.GetContext().Height {
		t.Fatalf("height %d", items[id].CreatedHeight)
	}

	testing.SetOriginCaller(bob)
	if score := VoteItem(cross(cur), id, 1); score != 1 {
		t.Fatalf("score %d", score)
	}
	if Karma(alice) != 1 {
		t.Fatalf("karma %d", Karma(alice))
	}
	if VoteItem(cross(cur), id, -1) != -1 {
		t.Fatalf("downs %d %d", items[id].Ups, items[id].Downs)
	}
	if Karma(alice) != -1 {
		t.Fatalf("karma after switch %d", Karma(alice))
	}
	if VoteItem(cross(cur), id, 0) != 0 {
		t.Fatal("clear failed")
	}
	if Karma(alice) != 0 || items[id].Ups != 0 || items[id].Downs != 0 {
		t.Fatalf("cleared ups=%d downs=%d karma=%d", items[id].Ups, items[id].Downs, Karma(alice))
	}
	// Voting the same way twice does not move the score.
	VoteItem(cross(cur), id, 1)
	VoteItem(cross(cur), id, 1)
	if items[id].Ups != 1 {
		t.Fatalf("double up counted %d", items[id].Ups)
	}

	testing.SetOriginCaller(alice)
	mustPanic(t, "cannot vote on your own post", func() {
		VoteItem(cross(cur), id, 1)
	})
	testing.SetOriginCaller(bob)
	mustPanic(t, "vote must be -1, 0, or 1", func() {
		VoteItem(cross(cur), id, 2)
	})
}

func TestDuplicateRateAndValidation(cur realm, t *testing.T) {
	boot()
	testing.SetOriginCaller(alice)
	Submit(cross(cur), "First link", "https://example.com/a", "")
	testing.SetOriginCaller(bob)
	mustPanic(t, "duplicate url", func() {
		Submit(cross(cur), "Same link", "https://example.com/a#frag", "")
	})
	testing.SetOriginCaller(alice)
	mustPanic(t, "rate limited", func() {
		Submit(cross(cur), "Second link", "https://example.com/b", "")
	})
	bump(RateLimitBlocks)
	testing.SetOriginCaller(alice)
	id := Submit(cross(cur), "Second link", "https://example.com/b", "")
	if id != 2 {
		t.Fatalf("id %d", id)
	}
	bump(RateLimitBlocks)
	testing.SetOriginCaller(alice)
	mustPanic(t, "title must be 4 to 120 characters", func() {
		Submit(cross(cur), "no", "https://example.com/c", "")
	})
	mustPanic(t, "invalid url", func() {
		Submit(cross(cur), "Valid title", "javascript:alert(1)", "")
	})
	testing.SetRealm(testing.NewCodeRealm("gno.land/r/demo/other"))
	mustPanic(t, "direct user call required", func() {
		Submit(cross(cur), "Valid title", "https://example.com/d", "")
	})
}

func TestCommentsThread(cur realm, t *testing.T) {
	boot()
	testing.SetOriginCaller(alice)
	itemID := Submit(cross(cur), "Thread me", "https://example.com/thread", "")
	testing.SetOriginCaller(bob)
	top := Comment(cross(cur), itemID, 0, "  top level  ")
	if comments[top].Body != "top level" {
		t.Fatalf("body %q", comments[top].Body)
	}
	testing.SetOriginCaller(carol)
	child := Comment(cross(cur), itemID, top, "a reply")
	if comments[child].ParentID != top {
		t.Fatal("parent not stored")
	}
	if VoteComment(cross(cur), top, 1) != 1 {
		t.Fatal("comment vote")
	}
	// Carol wrote the child, so she cannot vote it. Bob votes the child.
	testing.SetOriginCaller(bob)
	if VoteComment(cross(cur), child, 1) != 1 {
		t.Fatal("reply vote")
	}
	if Karma(bob) != 1 || Karma(carol) != 1 {
		t.Fatalf("bob %d carol %d", Karma(bob), Karma(carol))
	}
	testing.SetOriginCaller(alice)
	mustPanic(t, "parent comment not found", func() {
		Comment(cross(cur), itemID, 99, "orphan")
	})
	testing.SetOriginCaller(bob)
	mustPanic(t, "cannot vote on your own post", func() {
		VoteComment(cross(cur), top, -1)
	})
}

func TestCommentDepth(cur realm, t *testing.T) {
	boot()
	testing.SetOriginCaller(alice)
	Claim(cross(cur))
	itemID := Submit(cross(cur), "Deep thread", "https://example.com/deep", "")
	parent := uint64(0)
	var last uint64
	for i := 0; i < 6; i++ {
		last = Comment(cross(cur), itemID, parent, "level "+strconv.Itoa(i+1))
		parent = last
	}
	mustPanic(t, "comment is nested too deeply", func() {
		Comment(cross(cur), itemID, last, "too deep")
	})
}

func TestModerationAndOwnership(cur realm, t *testing.T) {
	boot()
	testing.SetOriginCaller(alice)
	Claim(cross(cur))
	testing.SetOriginCaller(bob)
	mustPanic(t, "already claimed", func() {
		Claim(cross(cur))
	})
	id := Submit(cross(cur), "Hide this", "https://example.com/hide", "secret")
	testing.SetOriginCaller(carol)
	VoteItem(cross(cur), id, 1)
	if Karma(bob) != 1 {
		t.Fatalf("karma before hide %d", Karma(bob))
	}
	mustPanic(t, "moderator only", func() {
		HideItem(cross(cur), id)
	})
	testing.SetOriginCaller(alice)
	GrantMod(cross(cur), carol)
	testing.SetOriginCaller(carol)
	HideItem(cross(cur), id)
	if !items[id].Hidden {
		t.Fatal("not hidden")
	}
	if strings.Contains(Render(""), "Hide this") {
		t.Fatal("hidden item still listed")
	}
	if !strings.Contains(Render("item/1"), "hidden") {
		t.Fatal(Render("item/1"))
	}
	testing.SetOriginCaller(alice)
	mustPanic(t, "item is closed", func() {
		VoteItem(cross(cur), id, 1)
	})
	UnhideItem(cross(cur), id)
	if items[id].Hidden || !strings.Contains(Render(""), "Hide this") {
		t.Fatal("unhide failed")
	}

	testing.SetOriginCaller(carol)
	RemoveItem(cross(cur), id)
	if Karma(bob) != 0 {
		t.Fatalf("karma not reversed: %d", Karma(bob))
	}
	if _, ok := urls["https://example.com/hide"]; ok {
		t.Fatal("url still reserved")
	}
	bump(RateLimitBlocks)
	testing.SetOriginCaller(bob)
	again := Submit(cross(cur), "Posted again", "https://example.com/hide", "")
	if again == id {
		t.Fatal("id reused")
	}

	testing.SetOriginCaller(alice)
	TransferOwnership(cross(cur), bob)
	mustPanic(t, "owner only", func() {
		GrantMod(cross(cur), alice)
	})
	testing.SetOriginCaller(bob)
	RevokeMod(cross(cur), carol)
	if IsModerator(carol) {
		t.Fatal("mod remains")
	}
	if Owner() != bob {
		t.Fatal("owner")
	}
}

func TestRenderRoutes(cur realm, t *testing.T) {
	boot()
	page := Render("")
	if !strings.Contains(page, "# Burrow") || !strings.Contains(page, "$help&func=Submit") {
		t.Fatalf("front page:\n%s", page)
	}
	if !strings.Contains(page, "Claim") {
		t.Fatal("unclaimed realm should offer Claim")
	}
	testing.SetOriginCaller(alice)
	Submit(cross(cur), "Alpha story", "https://example.com/alpha", "hello alpha")
	bump(RateLimitBlocks)
	testing.SetOriginCaller(bob)
	Submit(cross(cur), "Beta story", "https://example.com/beta", "")
	testing.SetOriginCaller(carol)
	VoteItem(cross(cur), 2, 1)
	hot := Render("hot")
	alpha := strings.Index(hot, "Alpha story")
	beta := strings.Index(hot, "Beta story")
	if alpha < 0 || beta < 0 || beta > alpha {
		t.Fatalf("hot order alpha=%d beta=%d\n%s", alpha, beta, hot)
	}
	newest := Render("/new")
	if strings.Index(newest, "Beta story") > strings.Index(newest, "Alpha story") {
		t.Fatalf("new order:\n%s", newest)
	}
	item := Render("item/1")
	if !strings.Contains(item, "https://example.com/alpha") || !strings.Contains(item, "hello alpha") {
		t.Fatalf("item:\n%s", item)
	}
	if !strings.Contains(item, "$help&func=VoteItem") || !strings.Contains(item, "$help&func=Comment") {
		t.Fatalf("item actions:\n%s", item)
	}
	user := Render("user/" + alice.String())
	if !strings.Contains(user, "Alpha story") || !strings.Contains(user, "Karma") {
		t.Fatalf("user:\n%s", user)
	}
	if !strings.Contains(Render("user/nope"), "Not found") {
		t.Fatal("bad address")
	}
	if !strings.Contains(Render("missing"), "Not found") {
		t.Fatal("bad path")
	}
	help := Render("submit")
	if !strings.Contains(help, realmPkgPath) || !strings.Contains(help, "-func Submit") {
		t.Fatalf("submit help:\n%s", help)
	}
}

func TestPagination(cur realm, t *testing.T) {
	boot()
	testing.SetOriginCaller(alice)
	for i := 1; i <= 21; i++ {
		if i > 1 {
			bump(RateLimitBlocks)
			testing.SetOriginCaller(alice)
		}
		Submit(cross(cur), "Link number "+strconv.Itoa(i), "https://example.com/p/"+strconv.Itoa(i), "")
	}
	page := Render("new?page=2")
	if !strings.Contains(page, "page 2 of 2") {
		t.Fatalf("pager:\n%s", page)
	}
	if !strings.Contains(page, "Link number 1") {
		t.Fatal("oldest item missing from page 2")
	}
	if strings.Contains(page, "Link number 21") {
		t.Fatal("newest item leaked onto page 2")
	}
}
