package burrow

import (
	"strconv"
	"strings"
	"time"

	"chain"
	"chain/runtime"
)

// realmPkgPath is the on-chain path of this realm.
// scripts/deploy-onyx.sh rewrites the faddat segment when the deploy
// namespace is not faddat. webBase is derived from it, so links follow.
const realmPkgPath = "gno.land/r/faddat/burrow"

// RateLimitBlocks is the quiet period between submissions and comments
// from the same address. Votes are not limited. The owner and moderators
// are exempt so they can keep moderating.
const RateLimitBlocks int64 = 20

// MaxCommentsPerItem caps a thread so one submission cannot grow without bound.
const MaxCommentsPerItem = 200

type item struct {
	ID            uint64
	Author        address
	Title         string
	URL           string
	Text          string
	CreatedUnix   int64
	CreatedHeight int64
	Ups           int
	Downs         int
	Hidden        bool
	Removed       bool
	Comments      []uint64
}

type comment struct {
	ID            uint64
	ItemID        uint64
	ParentID      uint64
	Author        address
	Body          string
	CreatedUnix   int64
	CreatedHeight int64
	Ups           int
	Downs         int
	Hidden        bool
	Removed       bool
}

type profile struct {
	Karma       int
	Submissions []uint64
	Comments    []uint64
	LastHeight  int64
}

var (
	items    []item
	comments []comment
	votes    map[string]int
	urls     map[string]uint64
	profiles map[address]*profile
	mods     map[address]bool
	owner    address
)

func init() {
	boot()
}

func boot() {
	items = []item{{}}
	comments = []comment{{}}
	votes = map[string]int{}
	urls = map[string]uint64{}
	profiles = map[address]*profile{}
	mods = map[address]bool{}
	var zero address
	owner = zero
}

func webBase() string {
	return strings.TrimPrefix(realmPkgPath, "gno.land")
}

func nowUnix() int64 {
	return time.Now().Unix()
}

func height() int64 {
	return runtime.ChainHeight()
}

// Owner is the address that claimed the realm, or the zero address.
func Owner() address {
	return owner
}

// IsModerator reports whether addr is the owner or a granted moderator.
func IsModerator(addr address) bool {
	return isStaff(addr)
}

// Karma is the net votes an address has received on others' posts and comments.
func Karma(addr address) int {
	p := profiles[addr]
	if p == nil {
		return 0
	}
	return p.Karma
}

// SubmittedCount is how many submissions have been assigned an id,
// including hidden and removed ones.
func SubmittedCount() int {
	return len(items) - 1
}

// CommentTotal is how many comments have been assigned an id.
func CommentTotal() int {
	return len(comments) - 1
}

func isStaff(addr address) bool {
	if owner.IsValid() && addr == owner {
		return true
	}
	return mods[addr]
}

func profileOf(addr address) *profile {
	p := profiles[addr]
	if p == nil {
		p = &profile{LastHeight: -1}
		profiles[addr] = p
	}
	return p
}

func adjustKarma(addr address, delta int) {
	if delta == 0 {
		return
	}
	profileOf(addr).Karma += delta
}

func validItem(id uint64) bool {
	return id > 0 && id < uint64(len(items))
}

func validComment(id uint64) bool {
	return id > 0 && id < uint64(len(comments))
}

func voteKey(kind string, id uint64, addr address) string {
	return kind + "/" + strconv.FormatUint(id, 10) + "/" + addr.String()
}

func scoreOf(ups, downs int) int {
	return ups - downs
}

func u64(n uint64) string {
	return strconv.FormatUint(n, 10)
}

func i64(n int64) string {
	return strconv.FormatInt(n, 10)
}

func emit(typ string, kv ...string) {
	chain.Emit(typ, kv...)
}
