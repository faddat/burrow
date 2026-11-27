package burrow

import core "gno.land/p/faddat/burrow"

// Comment adds a reply on a submission.
// parentID is 0 for a top-level comment, or another comment on the same submission.
func Comment(cur realm, itemID uint64, parentID uint64, body string) uint64 {
	addr := caller(cur)
	if !validItem(itemID) {
		panic("item not found")
	}
	if items[itemID].Hidden || items[itemID].Removed {
		panic("item is closed")
	}
	body, ok := core.NormalizeComment(body)
	if !ok {
		panic("comment must be 1 to 2000 characters")
	}
	if parentID != 0 {
		if !validComment(parentID) || comments[parentID].ItemID != itemID {
			panic("parent comment not found")
		}
		if comments[parentID].Hidden || comments[parentID].Removed {
			panic("item is closed")
		}
		if commentDepth(parentID) >= core.MaxCommentDepth {
			panic("comment is nested too deeply")
		}
	}
	if len(items[itemID].Comments) >= MaxCommentsPerItem {
		panic("too many comments on this item")
	}
	touchRate(addr)

	id := uint64(len(comments))
	comments = append(comments, comment{
		ID:            id,
		ItemID:        itemID,
		ParentID:      parentID,
		Author:        addr,
		Body:          body,
		CreatedUnix:   nowUnix(),
		CreatedHeight: height(),
	})
	items[itemID].Comments = append(items[itemID].Comments, id)
	p := profileOf(addr)
	p.Comments = append(p.Comments, id)

	emit("CommentSubmitted",
		"id", u64(id),
		"item", u64(itemID),
		"parent", u64(parentID),
		"author", addr.String(),
		"height", i64(height()),
	)
	return id
}

// VoteComment sets the caller's vote on a comment.
// dir is 1 (up), -1 (down), or 0 (clear).
func VoteComment(cur realm, id uint64, dir int) int {
	addr := caller(cur)
	if !validComment(id) {
		panic("comment not found")
	}
	c := comments[id]
	if c.Hidden || c.Removed {
		panic("item is closed")
	}
	if !validItem(c.ItemID) || items[c.ItemID].Hidden || items[c.ItemID].Removed {
		panic("item is closed")
	}
	if addr == c.Author {
		panic("cannot vote on your own post")
	}
	ups := comments[id].Ups
	downs := comments[id].Downs
	score, changed := applyVote("comment", id, addr, c.Author, dir, &ups, &downs)
	comments[id].Ups = ups
	comments[id].Downs = downs
	if changed {
		emit("CommentVoted",
			"id", u64(id),
			"voter", addr.String(),
			"dir", i64(int64(dir)),
			"score", i64(int64(score)),
		)
	}
	return score
}

// commentDepth counts nodes from id up to the root, inclusive.
func commentDepth(id uint64) int {
	depth := 0
	seen := 0
	for id != 0 {
		depth++
		seen++
		if seen > core.MaxCommentDepth+1 {
			panic("comment cycle")
		}
		id = comments[id].ParentID
	}
	return depth
}
