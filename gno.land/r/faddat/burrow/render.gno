package burrow

import (
	"net/url"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	core "gno.land/p/faddat/burrow"
)

// Render serves gnoweb markdown.
//
//	/            hot ranking
//	/new         newest first
//	/top         highest score
//	/item/<id>   one submission and its thread
//	/user/<addr> submissions, comments, and karma
//	/submit      how to post from gnoweb or gnokey
func Render(path string) string {
	route, query := splitPath(path)
	switch {
	case route == "" || route == "hot":
		return renderList("hot", "Hot", query)
	case route == "new":
		return renderList("new", "New", query)
	case route == "top":
		return renderList("top", "Top", query)
	case route == "submit":
		return renderSubmit()
	case strings.HasPrefix(route, "item/"):
		return renderItem(strings.TrimPrefix(route, "item/"), query)
	case strings.HasPrefix(route, "user/"):
		return renderUser(strings.TrimPrefix(route, "user/"))
	default:
		return notFound("That path is not a burrow page.")
	}
}

func splitPath(path string) (string, string) {
	path = strings.TrimSpace(path)
	query := ""
	if i := strings.IndexByte(path, '?'); i >= 0 {
		query = path[i+1:]
		path = path[:i]
	}
	path = strings.Trim(path, "/")
	return path, query
}

func queryPage(q string) int {
	vals, err := url.ParseQuery(q)
	if err != nil {
		return 1
	}
	n, err := strconv.Atoi(vals.Get("page"))
	if err != nil || n < 1 {
		return 1
	}
	return n
}

func notFound(msg string) string {
	var b strings.Builder
	b.WriteString(header())
	b.WriteString("# Not found\n\n")
	b.WriteString(msg)
	b.WriteString("\n\n")
	b.WriteString(mdLink("Back to the front page", webBase()))
	b.WriteString("\n")
	return b.String()
}

func header() string {
	base := webBase()
	return "# Burrow\n\n" +
		mdLink("hot", base) + " · " +
		mdLink("new", routeLink("new", "")) + " · " +
		mdLink("top", routeLink("top", "")) + " · " +
		mdLink("submit", routeLink("submit", "")) + "\n\n"
}

func routeLink(route, query string) string {
	base := webBase()
	if route == "" && query == "" {
		return base
	}
	if route == "" {
		return base + ":?" + query
	}
	if query == "" {
		return base + ":" + route
	}
	return base + ":" + route + "?" + query
}

func mdLink(label, href string) string {
	return "[" + label + "](" + href + ")"
}

func mdText(s string) string {
	s = strings.NewReplacer(
		"\\", "\\\\",
		"[", "\\[",
		"]", "\\]",
		"*", "\\*",
		"_", "\\_",
		"`", "\\`",
		"<", "&lt;",
		">", "&gt;",
	).Replace(s)
	return s
}

func renderList(kind, title, query string) string {
	var b strings.Builder
	b.WriteString(header())
	b.WriteString("## ")
	b.WriteString(title)
	b.WriteString("\n\n")
	switch kind {
	case "hot":
		b.WriteString("Score decays with a 6 hour half-life, using the block time.\n\n")
	case "new":
		b.WriteString("Newest submissions first.\n\n")
	case "top":
		b.WriteString("Highest score first. Score is upvotes minus downvotes.\n\n")
	}
	ids := rankedIDs(kind)
	w := core.Paginate(queryPage(query), core.PageSize, len(ids))
	if len(ids) == 0 {
		b.WriteString("No submissions yet. ")
		b.WriteString(mdLink("Submit a link", core.TxLink(webBase(), "Submit")))
		b.WriteString(".\n")
		b.WriteString(footer())
		return b.String()
	}
	end := w.Offset + w.Limit
	for i := w.Offset; i < end; i++ {
		b.WriteString(itemLine(ids[i], i+1))
		b.WriteString("\n")
	}
	b.WriteString(pager(kindRoute(kind), w))
	b.WriteString(footer())
	return b.String()
}

func kindRoute(kind string) string {
	if kind == "hot" {
		return ""
	}
	return kind
}

func rankedIDs(kind string) []uint64 {
	ids := make([]uint64, 0, len(items))
	for id := uint64(1); id < uint64(len(items)); id++ {
		if items[id].Hidden || items[id].Removed {
			continue
		}
		ids = append(ids, id)
	}
	now := nowUnix()
	switch kind {
	case "new":
		sortIDs(ids, func(a, b uint64) bool { return a > b })
	case "top":
		sortIDs(ids, func(a, b uint64) bool {
			sa := scoreOf(items[a].Ups, items[a].Downs)
			sb := scoreOf(items[b].Ups, items[b].Downs)
			if sa != sb {
				return sa > sb
			}
			return a > b
		})
	default:
		sortIDs(ids, func(a, b uint64) bool {
			ha := core.HotScore(scoreOf(items[a].Ups, items[a].Downs), items[a].CreatedUnix, now)
			hb := core.HotScore(scoreOf(items[b].Ups, items[b].Downs), items[b].CreatedUnix, now)
			if ha != hb {
				return ha > hb
			}
			return a > b
		})
	}
	return ids
}

func sortIDs(ids []uint64, less func(a, b uint64) bool) {
	for i := 1; i < len(ids); i++ {
		v := ids[i]
		j := i
		for j > 0 && less(v, ids[j-1]) {
			ids[j] = ids[j-1]
			j--
		}
		ids[j] = v
	}
}

func itemLine(id uint64, n int) string {
	it := items[id]
	itemPath := routeLink("item/"+u64(id), "")
	var b strings.Builder
	b.WriteString("**")
	b.WriteString(strconv.Itoa(n))
	b.WriteString(". ")
	b.WriteString(mdLink(mdText(it.Title), itemPath))
	b.WriteString("** · ")
	b.WriteString(mdLink(mdText(hostOf(it.URL)), it.URL))
	b.WriteString("\n\n")
	b.WriteString(scoreText(it.Ups, it.Downs))
	b.WriteString(" · ")
	b.WriteString(userLink(it.Author))
	b.WriteString(" · ")
	b.WriteString(formatTime(it.CreatedUnix))
	b.WriteString(" · block ")
	b.WriteString(i64(it.CreatedHeight))
	b.WriteString(" · ")
	b.WriteString(mdLink(strconv.Itoa(len(it.Comments))+" comments", itemPath))
	b.WriteString(" · ")
	b.WriteString(voteLinks("VoteItem", id))
	if it.Text != "" {
		b.WriteString("\n\n")
		b.WriteString(mdText(excerpt(it.Text, 180)))
	}
	b.WriteString("\n")
	return b.String()
}

func renderItem(idRaw, query string) string {
	id, err := strconv.ParseUint(idRaw, 10, 64)
	if err != nil || !validItem(id) {
		return notFound("No submission with that id.")
	}
	it := items[id]
	var b strings.Builder
	b.WriteString(header())
	if it.Removed {
		b.WriteString("# Removed\n\nThis submission was removed by a moderator.\n\n")
		b.WriteString(footer())
		return b.String()
	}
	if it.Hidden {
		b.WriteString("# Hidden\n\nThis submission is hidden. Listings skip it.\n\n")
		b.WriteString(footer())
		return b.String()
	}
	b.WriteString("# ")
	b.WriteString(mdText(it.Title))
	b.WriteString("\n\n")
	b.WriteString(mdLink(mdText(it.URL), it.URL))
	b.WriteString("\n\n")
	b.WriteString(scoreText(it.Ups, it.Downs))
	b.WriteString(" · ")
	b.WriteString(userLink(it.Author))
	b.WriteString(" · ")
	b.WriteString(formatTime(it.CreatedUnix))
	b.WriteString(" · block ")
	b.WriteString(i64(it.CreatedHeight))
	b.WriteString(" · ")
	b.WriteString(voteLinks("VoteItem", id))
	b.WriteString("\n\n")
	if it.Text != "" {
		b.WriteString(mdText(it.Text))
		b.WriteString("\n\n")
	}
	b.WriteString("---\n\n## Comments\n\n")
	b.WriteString(mdLink("Add a comment", core.TxLink(webBase(), "Comment",
		"itemID", u64(id),
		"parentID", "0",
		"body", "",
	)))
	b.WriteString("\n\n")
	order, depths := commentOrder(id)
	w := core.Paginate(queryPage(query), core.PageSize, len(order))
	if len(order) == 0 {
		b.WriteString("No comments yet.\n")
	} else {
		end := w.Offset + w.Limit
		for i := w.Offset; i < end; i++ {
			b.WriteString(renderComment(order[i], depths[i]))
			b.WriteString("\n")
		}
		b.WriteString(pager("item/"+u64(id), w))
	}
	b.WriteString("\n\n### Moderation\n\n")
	b.WriteString(mdLink("hide", core.TxLink(webBase(), "HideItem", "id", u64(id))))
	b.WriteString(" · ")
	b.WriteString(mdLink("unhide", core.TxLink(webBase(), "UnhideItem", "id", u64(id))))
	b.WriteString(" · ")
	b.WriteString(mdLink("remove", core.TxLink(webBase(), "RemoveItem", "id", u64(id))))
	b.WriteString("\n\n")
	b.WriteString(footer())
	return b.String()
}

func commentOrder(itemID uint64) ([]uint64, []int) {
	children := map[uint64][]uint64{}
	for _, cid := range items[itemID].Comments {
		parent := comments[cid].ParentID
		children[parent] = append(children[parent], cid)
	}
	var order []uint64
	var depths []int
	var walk func(parent uint64, depth int)
	walk = func(parent uint64, depth int) {
		for _, cid := range children[parent] {
			order = append(order, cid)
			depths = append(depths, depth)
			walk(cid, depth+1)
		}
	}
	walk(0, 0)
	return order, depths
}

func renderComment(id uint64, depth int) string {
	c := comments[id]
	var body string
	switch {
	case c.Removed:
		body = "_removed_"
	case c.Hidden:
		body = "_hidden by a moderator_"
	default:
		body = mdText(c.Body)
	}
	var b strings.Builder
	prefix := strings.Repeat("> ", depth+1)
	b.WriteString(prefix)
	b.WriteString("**")
	b.WriteString(userLink(c.Author))
	b.WriteString("** · ")
	b.WriteString(scoreText(c.Ups, c.Downs))
	b.WriteString(" · ")
	b.WriteString(formatTime(c.CreatedUnix))
	if !c.Removed && !c.Hidden {
		b.WriteString(" · ")
		b.WriteString(mdLink("reply", core.TxLink(webBase(), "Comment",
			"itemID", u64(c.ItemID),
			"parentID", u64(id),
			"body", "",
		)))
		b.WriteString(" · ")
		b.WriteString(voteLinks("VoteComment", id))
	}
	b.WriteString("\n")
	b.WriteString(prefix)
	b.WriteString("\n")
	for _, line := range strings.Split(body, "\n") {
		b.WriteString(prefix)
		b.WriteString(line)
		b.WriteString("\n")
	}
	return b.String()
}

func renderUser(raw string) string {
	addr, ok := parseAddr(raw)
	if !ok {
		return notFound("That is not an address.")
	}
	var b strings.Builder
	b.WriteString(header())
	b.WriteString("# ")
	b.WriteString(addr.String())
	b.WriteString("\n\nKarma **")
	b.WriteString(strconv.Itoa(Karma(addr)))
	b.WriteString("**")
	p := profiles[addr]
	if p == nil {
		b.WriteString("\n\nNo activity yet.\n")
		b.WriteString(footer())
		return b.String()
	}
	b.WriteString(" · ")
	b.WriteString(strconv.Itoa(len(p.Submissions)))
	b.WriteString(" submissions · ")
	b.WriteString(strconv.Itoa(len(p.Comments)))
	b.WriteString(" comments\n\n## Submissions\n\n")
	if len(p.Submissions) == 0 {
		b.WriteString("None yet.\n\n")
	}
	for i := len(p.Submissions) - 1; i >= 0; i-- {
		id := p.Submissions[i]
		it := items[id]
		b.WriteString("- ")
		switch {
		case it.Removed:
			b.WriteString("removed submission #")
			b.WriteString(u64(id))
		case it.Hidden:
			b.WriteString("hidden submission #")
			b.WriteString(u64(id))
		default:
			b.WriteString(mdLink(mdText(it.Title), routeLink("item/"+u64(id), "")))
			b.WriteString(" · ")
			b.WriteString(scoreText(it.Ups, it.Downs))
		}
		b.WriteString("\n")
	}
	b.WriteString("\n## Comments\n\n")
	if len(p.Comments) == 0 {
		b.WriteString("None yet.\n")
	}
	for i := len(p.Comments) - 1; i >= 0; i-- {
		id := p.Comments[i]
		c := comments[id]
		b.WriteString("- ")
		if !validItem(c.ItemID) || items[c.ItemID].Removed || items[c.ItemID].Hidden {
			b.WriteString("on a closed submission")
		} else {
			b.WriteString("on ")
			b.WriteString(mdLink(mdText(items[c.ItemID].Title), routeLink("item/"+u64(c.ItemID), "")))
		}
		b.WriteString(" · ")
		if c.Removed {
			b.WriteString("removed")
		} else if c.Hidden {
			b.WriteString("hidden")
		} else {
			b.WriteString(scoreText(c.Ups, c.Downs))
		}
		b.WriteString("\n")
	}
	b.WriteString(footer())
	return b.String()
}

func renderSubmit() string {
	var b strings.Builder
	b.WriteString(header())
	b.WriteString("## Submit a link\n\n")
	b.WriteString("Open the transaction in gnoweb and sign it with Adena, or copy the command below.\n\n")
	b.WriteString(mdLink("Open submit", core.TxLink(webBase(), "Submit")))
	b.WriteString("\n\n")
	b.WriteString("- `title` — ")
	b.WriteString(strconv.Itoa(core.MinTitleLen))
	b.WriteString(" to ")
	b.WriteString(strconv.Itoa(core.MaxTitleLen))
	b.WriteString(" characters, no line breaks\n")
	b.WriteString("- `url` — http or https. The host is lowercased, the fragment and a trailing slash are ignored, and a live duplicate is refused\n")
	b.WriteString("- `text` — optional note, up to ")
	b.WriteString(strconv.Itoa(core.MaxTextLen))
	b.WriteString(" bytes\n\n")
	b.WriteString("Each address may submit or comment once every ")
	b.WriteString(i64(RateLimitBlocks))
	b.WriteString(" blocks. Votes are one per address per submission or comment, and can be changed.\n\n")
	b.WriteString("```\ngnokey maketx call \\\n")
	b.WriteString("  -pkgpath \"")
	b.WriteString(realmPkgPath)
	b.WriteString("\" \\\n")
	b.WriteString("  -func Submit \\\n")
	b.WriteString("  -args \"A clear title\" \\\n")
	b.WriteString("  -args \"https://example.com/story\" \\\n")
	b.WriteString("  -args \"optional note\" \\\n")
	b.WriteString("  -gas-fee 10000ugnot -gas-wanted 10000000 \\\n")
	b.WriteString("  -chainid dev -remote http://127.0.0.1:26657 \\\n")
	b.WriteString("  KEYNAME\n```\n")
	b.WriteString(footer())
	return b.String()
}

func footer() string {
	var b strings.Builder
	b.WriteString("\n---\n\n")
	if owner.IsValid() {
		b.WriteString("Owner ")
		b.WriteString(userLink(owner))
	} else {
		b.WriteString("No owner yet. ")
		b.WriteString(mdLink("Claim", core.TxLink(webBase(), "Claim")))
	}
	b.WriteString(" · ")
	b.WriteString(mdLink("realm help", webBase()+"$help"))
	b.WriteString("\n")
	return b.String()
}

func voteLinks(fn string, id uint64) string {
	idStr := u64(id)
	return mdLink("up", core.TxLink(webBase(), fn, "id", idStr, "dir", "1")) +
		" · " +
		mdLink("down", core.TxLink(webBase(), fn, "id", idStr, "dir", "-1")) +
		" · " +
		mdLink("clear", core.TxLink(webBase(), fn, "id", idStr, "dir", "0"))
}

func userLink(addr address) string {
	return mdLink(addr.String(), routeLink("user/"+addr.String(), ""))
}

func scoreText(ups, downs int) string {
	return "+" + strconv.Itoa(ups) + " -" + strconv.Itoa(downs)
}

func formatTime(unix int64) string {
	return time.Unix(unix, 0).UTC().Format("2006-01-02 15:04 UTC")
}

func hostOf(raw string) string {
	u, err := url.Parse(raw)
	if err != nil || u.Hostname() == "" {
		return "link"
	}
	return u.Hostname()
}

func excerpt(s string, n int) string {
	if utf8.RuneCountInString(s) <= n {
		return s
	}
	i := 0
	for j := range s {
		if i == n {
			return s[:j] + "..."
		}
		i++
	}
	return s
}

func pager(route string, w core.Window) string {
	if w.Pages <= 1 {
		return ""
	}
	var b strings.Builder
	b.WriteString("\n")
	if w.Page > 1 {
		q := ""
		if w.Page-1 > 1 {
			q = "page=" + strconv.Itoa(w.Page-1)
		}
		b.WriteString(mdLink("prev", routeLink(route, q)))
		b.WriteString(" · ")
	}
	b.WriteString("page ")
	b.WriteString(strconv.Itoa(w.Page))
	b.WriteString(" of ")
	b.WriteString(strconv.Itoa(w.Pages))
	if w.Page < w.Pages {
		b.WriteString(" · ")
		b.WriteString(mdLink("next", routeLink(route, "page="+strconv.Itoa(w.Page+1))))
	}
	b.WriteString("\n")
	return b.String()
}

func parseAddr(s string) (addr address, ok bool) {
	defer func() { recover() }()
	addr = address(s)
	if !addr.IsValid() {
		return
	}
	ok = true
	return
}
