// PKGPATH: gno.land/r/faddat/burrow/filetests/submit_thread_filetest

package submit_thread_filetest

import (
	"testing"

	burrow "gno.land/r/faddat/burrow"
)

const (
	alice address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"
	bob   address = "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
)

func main(cur realm) {
	testing.SetOriginCaller(alice)
	id := burrow.Submit(cross(cur), "Hello burrow", "https://example.com/hello", "first post")
	println("id", id)
	testing.SetOriginCaller(bob)
	println("score", burrow.VoteItem(cross(cur), id, 1))
	cid := burrow.Comment(cross(cur), id, 0, "nice link")
	println("comment", cid)
	testing.SetOriginCaller(alice)
	println("reply", burrow.Comment(cross(cur), id, cid, "thanks"))
	println("---")
	println(burrow.Render("item/1"))
	println("---")
	println(burrow.Render("user/" + alice.String()))
}

// Output:
// id 1
// score 1
// comment 1

// Events:
// [
//   {
//     "type": "ItemSubmitted",
//     "attrs": [
//       {
//         "key": "id",
//         "value": "1"
//       },
//       {
//         "key": "author",
//         "value": "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"
//       },
//       {
//         "key": "title",
//         "value": "Hello burrow"
//       },
//       {
//         "key": "url",
//         "value": "https://example.com/hello"
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
//         "value": "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
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
//     "type": "CommentSubmitted",
//     "attrs": [
//       {
//         "key": "id",
//         "value": "1"
//       },
//       {
//         "key": "item",
//         "value": "1"
//       },
//       {
//         "key": "parent",
//         "value": "0"
//       },
//       {
//         "key": "author",
//         "value": "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
//       },
//       {
//         "key": "height",
//         "value": "123"
//       }
//     ],
//     "pkg_path": "gno.land/r/faddat/burrow"
//   }
// ]

// Error:
// rate limited
