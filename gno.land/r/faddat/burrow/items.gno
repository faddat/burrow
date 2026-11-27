package burrow

import core "gno.land/p/faddat/burrow"

// Submit posts a link. text may be empty.
// The URL is normalized, and a second live submission of the same URL is refused.
func Submit(cur realm, title, url, text string) uint64 {
	addr := caller(cur)
	title, ok := core.NormalizeTitle(title)
	if !ok {
		panic("title must be 4 to 120 characters")
	}
	url, ok = core.NormalizeURL(url)
	if !ok {
		panic("invalid url")
	}
	text, ok = core.NormalizeText(text)
	if !ok {
		panic("text is too long")
	}
	if _, exists := urls[url]; exists {
		panic("duplicate url")
	}
	touchRate(addr)

	id := uint64(len(items))
	items = append(items, item{
		ID:            id,
		Author:        addr,
		Title:         title,
		URL:           url,
		Text:          text,
		CreatedUnix:   nowUnix(),
		CreatedHeight: height(),
	})
	urls[url] = id
	p := profileOf(addr)
	p.Submissions = append(p.Submissions, id)

	emit("ItemSubmitted",
		"id", u64(id),
		"author", addr.String(),
		"title", title,
		"url", url,
		"height", i64(height()),
	)
	return id
}

// VoteItem sets the caller's vote on a submission.
// dir is 1 (up), -1 (down), or 0 (clear). One vote is stored per address.
// Voting again with a different dir replaces the previous vote.
func VoteItem(cur realm, id uint64, dir int) int {
	addr := caller(cur)
	if !validItem(id) {
		panic("item not found")
	}
	if items[id].Hidden || items[id].Removed {
		panic("item is closed")
	}
	if addr == items[id].Author {
		panic("cannot vote on your own post")
	}
	ups := items[id].Ups
	downs := items[id].Downs
	score, changed := applyVote("item", id, addr, items[id].Author, dir, &ups, &downs)
	items[id].Ups = ups
	items[id].Downs = downs
	if changed {
		emit("ItemVoted",
			"id", u64(id),
			"voter", addr.String(),
			"dir", i64(int64(dir)),
			"score", i64(int64(score)),
		)
	}
	return score
}

func applyVote(kind string, id uint64, voter, author address, dir int, ups, downs *int) (int, bool) {
	if dir != -1 && dir != 0 && dir != 1 {
		panic("vote must be -1, 0, or 1")
	}
	key := voteKey(kind, id, voter)
	old := votes[key]
	if old == dir {
		return scoreOf(*ups, *downs), false
	}
	switch old {
	case 1:
		*ups--
	case -1:
		*downs--
	}
	switch dir {
	case 1:
		*ups++
		votes[key] = dir
	case -1:
		*downs++
		votes[key] = dir
	default:
		delete(votes, key)
	}
	adjustKarma(author, dir-old)
	return scoreOf(*ups, *downs), true
}
