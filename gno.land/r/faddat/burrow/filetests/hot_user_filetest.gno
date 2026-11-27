// PKGPATH: gno.land/r/faddat/burrow/filetests/hot_user_filetest

package hot_user_filetest

import (
	"testing"

	burrow "gno.land/r/faddat/burrow"
)

const (
	alice address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"
	bob   address = "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
)

func bump(blocks int64) {
	ctx := testing.GetContext()
	testing.SetHeight(ctx.Height + blocks)
}

func main(cur realm) {
	testing.SetOriginCaller(alice)
	burrow.Submit(cross(cur), "Older quiet", "https://example.com/old", "")
	bump(burrow.RateLimitBlocks)
	testing.SetOriginCaller(alice)
	burrow.Submit(cross(cur), "Newer loud", "https://example.com/new", "")
	testing.SetOriginCaller(bob)
	burrow.VoteItem(cross(cur), 2, 1)
	println("HOT")
	println(burrow.Render("hot"))
	println("NEW")
	println(burrow.Render("new"))
	println("TOP")
	println(burrow.Render("top"))
	println("USER")
	println(burrow.Render("user/" + bob.String()))
}

// Output:
// HOT
// # Burrow
//
// [hot](/r/faddat/burrow) · [new](/r/faddat/burrow:new) · [top](/r/faddat/burrow:top) · [submit](/r/faddat/burrow:submit)
//
// ## Hot
//
// Score decays with a 6 hour half-life, using the block time.
//
// **1. [Newer loud](/r/faddat/burrow:item/2)** · [example.com](https://example.com/new)
//
// +1 -0 · [g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5](/r/faddat/burrow:user/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5) · 2009-02-13 23:31 UTC · block 143 · [0 comments](/r/faddat/burrow:item/2) · [up](/r/faddat/burrow$help&func=VoteItem&dir=1&id=2) · [down](/r/faddat/burrow$help&func=VoteItem&dir=-1&id=2) · [clear](/r/faddat/burrow$help&func=VoteItem&dir=0&id=2)
//
// **2. [Older quiet](/r/faddat/burrow:item/1)** · [example.com](https://example.com/old)
//
// +0 -0 · [g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5](/r/faddat/burrow:user/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5) · 2009-02-13 23:31 UTC · block 123 · [0 comments](/r/faddat/burrow:item/1) · [up](/r/faddat/burrow$help&func=VoteItem&dir=1&id=1) · [down](/r/faddat/burrow$help&func=VoteItem&dir=-1&id=1) · [clear](/r/faddat/burrow$help&func=VoteItem&dir=0&id=1)
//
//
// ---
//
// No owner yet. [Claim](/r/faddat/burrow$help&func=Claim) · [realm help](/r/faddat/burrow$help)
//
// NEW
// # Burrow
//
// [hot](/r/faddat/burrow) · [new](/r/faddat/burrow:new) · [top](/r/faddat/burrow:top) · [submit](/r/faddat/burrow:submit)
//
// ## New
//
// Newest submissions first.
//
// **1. [Newer loud](/r/faddat/burrow:item/2)** · [example.com](https://example.com/new)
//
// +1 -0 · [g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5](/r/faddat/burrow:user/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5) · 2009-02-13 23:31 UTC · block 143 · [0 comments](/r/faddat/burrow:item/2) · [up](/r/faddat/burrow$help&func=VoteItem&dir=1&id=2) · [down](/r/faddat/burrow$help&func=VoteItem&dir=-1&id=2) · [clear](/r/faddat/burrow$help&func=VoteItem&dir=0&id=2)
//
// **2. [Older quiet](/r/faddat/burrow:item/1)** · [example.com](https://example.com/old)
//
// +0 -0 · [g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5](/r/faddat/burrow:user/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5) · 2009-02-13 23:31 UTC · block 123 · [0 comments](/r/faddat/burrow:item/1) · [up](/r/faddat/burrow$help&func=VoteItem&dir=1&id=1) · [down](/r/faddat/burrow$help&func=VoteItem&dir=-1&id=1) · [clear](/r/faddat/burrow$help&func=VoteItem&dir=0&id=1)
//
//
// ---
//
// No owner yet. [Claim](/r/faddat/burrow$help&func=Claim) · [realm help](/r/faddat/burrow$help)
//
// TOP
// # Burrow
//
// [hot](/r/faddat/burrow) · [new](/r/faddat/burrow:new) · [top](/r/faddat/burrow:top) · [submit](/r/faddat/burrow:submit)
//
// ## Top
//
// Highest score first. Score is upvotes minus downvotes.
//
// **1. [Newer loud](/r/faddat/burrow:item/2)** · [example.com](https://example.com/new)
//
// +1 -0 · [g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5](/r/faddat/burrow:user/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5) · 2009-02-13 23:31 UTC · block 143 · [0 comments](/r/faddat/burrow:item/2) · [up](/r/faddat/burrow$help&func=VoteItem&dir=1&id=2) · [down](/r/faddat/burrow$help&func=VoteItem&dir=-1&id=2) · [clear](/r/faddat/burrow$help&func=VoteItem&dir=0&id=2)
//
// **2. [Older quiet](/r/faddat/burrow:item/1)** · [example.com](https://example.com/old)
//
// +0 -0 · [g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5](/r/faddat/burrow:user/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5) · 2009-02-13 23:31 UTC · block 123 · [0 comments](/r/faddat/burrow:item/1) · [up](/r/faddat/burrow$help&func=VoteItem&dir=1&id=1) · [down](/r/faddat/burrow$help&func=VoteItem&dir=-1&id=1) · [clear](/r/faddat/burrow$help&func=VoteItem&dir=0&id=1)
//
//
// ---
//
// No owner yet. [Claim](/r/faddat/burrow$help&func=Claim) · [realm help](/r/faddat/burrow$help)
//
// USER
// # Burrow
//
// [hot](/r/faddat/burrow) · [new](/r/faddat/burrow:new) · [top](/r/faddat/burrow:top) · [submit](/r/faddat/burrow:submit)
//
// # g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec
//
// Karma **0**
//
// No activity yet.
//
// ---
//
// No owner yet. [Claim](/r/faddat/burrow$help&func=Claim) · [realm help](/r/faddat/burrow$help)
