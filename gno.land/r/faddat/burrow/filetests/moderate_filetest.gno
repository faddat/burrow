// PKGPATH: gno.land/r/faddat/burrow/filetests/moderate_filetest

package moderate_filetest

import (
	"testing"

	burrow "gno.land/r/faddat/burrow"
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

func main(cur realm) {
	testing.SetOriginCaller(alice)
	burrow.Claim(cross(cur))
	burrow.GrantMod(cross(cur), carol)
	testing.SetOriginCaller(bob)
	id := burrow.Submit(cross(cur), "Hide this", "https://example.com/hide", "secret")
	testing.SetOriginCaller(carol)
	burrow.VoteItem(cross(cur), id, 1)
	burrow.HideItem(cross(cur), id)
	println("hidden", burrow.Render("item/1"))
	burrow.UnhideItem(cross(cur), id)
	println("karma-before", burrow.Karma(bob))
	burrow.RemoveItem(cross(cur), id)
	println("karma-after", burrow.Karma(bob))
	bump(burrow.RateLimitBlocks)
	testing.SetOriginCaller(bob)
	again := burrow.Submit(cross(cur), "Posted again", "https://example.com/hide", "")
	println("again", again)
	testing.SetOriginCaller(alice)
	burrow.TransferOwnership(cross(cur), bob)
	println("owner", burrow.Owner())
	testing.SetOriginCaller(bob)
	burrow.RevokeMod(cross(cur), carol)
	println("mod", burrow.IsModerator(carol))
}

// Output:
// hidden # Burrow
//
// [hot](/r/faddat/burrow) · [new](/r/faddat/burrow:new) · [top](/r/faddat/burrow:top) · [submit](/r/faddat/burrow:submit)
//
// # Hidden
//
// This submission is hidden. Listings skip it.
//
//
// ---
//
// Owner [g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5](/r/faddat/burrow:user/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5) · [realm help](/r/faddat/burrow$help)
//
// karma-before 1
// karma-after 0
// again 2
// owner g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec
// mod false

// Events:
// [
//   {
//     "type": "OwnershipClaimed",
//     "attrs": [
//       {
//         "key": "owner",
//         "value": "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "ModeratorGranted",
//     "attrs": [
//       {
//         "key": "owner",
//         "value": "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"
//       },
//       {
//         "key": "moderator",
//         "value": "g1skl80cuz8zq3lul9pgz5pc35l2pfzgxgfpsqkx"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "ItemSubmitted",
//     "attrs": [
//       {
//         "key": "id",
//         "value": "1"
//       },
//       {
//         "key": "author",
//         "value": "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
//       },
//       {
//         "key": "title",
//         "value": "Hide this"
//       },
//       {
//         "key": "url",
//         "value": "https://example.com/hide"
//       },
//       {
//         "key": "height",
//         "value": "123"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "ItemVoted",
//     "attrs": [
//       {
//         "key": "id",
//         "value": "1"
//       },
//       {
//         "key": "voter",
//         "value": "g1skl80cuz8zq3lul9pgz5pc35l2pfzgxgfpsqkx"
//       },
//       {
//         "key": "dir",
//         "value": "1"
//       },
//       {
//         "key": "score",
//         "value": "1"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "ItemHidden",
//     "attrs": [
//       {
//         "key": "id",
//         "value": "1"
//       },
//       {
//         "key": "by",
//         "value": "g1skl80cuz8zq3lul9pgz5pc35l2pfzgxgfpsqkx"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "ItemUnhidden",
//     "attrs": [
//       {
//         "key": "id",
//         "value": "1"
//       },
//       {
//         "key": "by",
//         "value": "g1skl80cuz8zq3lul9pgz5pc35l2pfzgxgfpsqkx"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "ItemRemoved",
//     "attrs": [
//       {
//         "key": "id",
//         "value": "1"
//       },
//       {
//         "key": "by",
//         "value": "g1skl80cuz8zq3lul9pgz5pc35l2pfzgxgfpsqkx"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "ItemSubmitted",
//     "attrs": [
//       {
//         "key": "id",
//         "value": "2"
//       },
//       {
//         "key": "author",
//         "value": "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
//       },
//       {
//         "key": "title",
//         "value": "Posted again"
//       },
//       {
//         "key": "url",
//         "value": "https://example.com/hide"
//       },
//       {
//         "key": "height",
//         "value": "143"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "OwnershipTransferred",
//     "attrs": [
//       {
//         "key": "from",
//         "value": "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"
//       },
//       {
//         "key": "to",
//         "value": "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   },
//   {
//     "type": "ModeratorRevoked",
//     "attrs": [
//       {
//         "key": "owner",
//         "value": "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
//       },
//       {
//         "key": "moderator",
//         "value": "g1skl80cuz8zq3lul9pgz5pc35l2pfzgxgfpsqkx"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   }
// ]
