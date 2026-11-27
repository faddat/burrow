package burrow

// HideItem drops a submission from public listings and redacts it on its page.
// The owner or a moderator can reverse it with UnhideItem.
func HideItem(cur realm, id uint64) {
	addr := caller(cur)
	requireMod(addr)
	if !validItem(id) {
		panic("item not found")
	}
	if items[id].Removed {
		panic("item is removed")
	}
	if items[id].Hidden {
		panic("already hidden")
	}
	items[id].Hidden = true
	emit("ItemHidden", "id", u64(id), "by", addr.String())
}

// UnhideItem returns a hidden submission to the listings.
func UnhideItem(cur realm, id uint64) {
	addr := caller(cur)
	requireMod(addr)
	if !validItem(id) {
		panic("item not found")
	}
	if items[id].Removed {
		panic("item is removed")
	}
	if !items[id].Hidden {
		panic("item is not hidden")
	}
	items[id].Hidden = false
	emit("ItemUnhidden", "id", u64(id), "by", addr.String())
}

// RemoveItem redacts a submission permanently and frees its URL
// so someone else may post it. Karma from votes on the submission is reversed.
func RemoveItem(cur realm, id uint64) {
	addr := caller(cur)
	requireMod(addr)
	if !validItem(id) {
		panic("item not found")
	}
	if items[id].Removed {
		panic("already removed")
	}
	items[id].Removed = true
	items[id].Hidden = false
	adjustKarma(items[id].Author, -(items[id].Ups - items[id].Downs))
	delete(urls, items[id].URL)
	emit("ItemRemoved", "id", u64(id), "by", addr.String())
}

// HideComment redacts one comment until UnhideComment.
func HideComment(cur realm, id uint64) {
	addr := caller(cur)
	requireMod(addr)
	if !validComment(id) {
		panic("comment not found")
	}
	if comments[id].Removed {
		panic("comment is removed")
	}
	if comments[id].Hidden {
		panic("already hidden")
	}
	comments[id].Hidden = true
	emit("CommentHidden", "id", u64(id), "by", addr.String())
}

// UnhideComment restores a hidden comment.
func UnhideComment(cur realm, id uint64) {
	addr := caller(cur)
	requireMod(addr)
	if !validComment(id) {
		panic("comment not found")
	}
	if comments[id].Removed {
		panic("comment is removed")
	}
	if !comments[id].Hidden {
		panic("comment is not hidden")
	}
	comments[id].Hidden = false
	emit("CommentUnhidden", "id", u64(id), "by", addr.String())
}

// RemoveComment redacts a comment permanently and reverses karma
// earned from votes on it.
func RemoveComment(cur realm, id uint64) {
	addr := caller(cur)
	requireMod(addr)
	if !validComment(id) {
		panic("comment not found")
	}
	if comments[id].Removed {
		panic("already removed")
	}
	comments[id].Removed = true
	comments[id].Hidden = false
	adjustKarma(comments[id].Author, -(comments[id].Ups - comments[id].Downs))
	emit("CommentRemoved", "id", u64(id), "by", addr.String())
}
