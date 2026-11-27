package burrow

import "chain/runtime"

func caller(cur realm) address {
	prev := cur.Previous()
	if !prev.IsUserCall() {
		panic("direct user call required")
	}
	addr := prev.Address()
	if !addr.IsValid() {
		panic("missing caller")
	}
	return addr
}

func requireOwner(addr address) {
	if !owner.IsValid() || addr != owner {
		panic("owner only")
	}
}

func requireMod(addr address) {
	if !isStaff(addr) {
		panic("moderator only")
	}
}

func touchRate(addr address) {
	if isStaff(addr) {
		return
	}
	p := profileOf(addr)
	h := runtime.ChainHeight()
	if p.LastHeight >= 0 && h < p.LastHeight+RateLimitBlocks {
		panic("rate limited")
	}
	p.LastHeight = h
}

// Claim makes the caller the owner. The first successful call wins.
// Run it immediately after deploy.
func Claim(cur realm) {
	addr := caller(cur)
	if owner.IsValid() {
		panic("already claimed")
	}
	owner = addr
	emit("OwnershipClaimed", "owner", addr.String())
}

// TransferOwnership hands the owner role to newOwner.
// Moderators are left in place.
func TransferOwnership(cur realm, newOwner address) {
	addr := caller(cur)
	requireOwner(addr)
	if !newOwner.IsValid() {
		panic("invalid address")
	}
	if newOwner == owner {
		panic("already the owner")
	}
	prev := owner
	owner = newOwner
	emit("OwnershipTransferred",
		"from", prev.String(),
		"to", newOwner.String(),
	)
}

// GrantMod lets addr hide and remove submissions and comments.
func GrantMod(cur realm, addr address) {
	callerAddr := caller(cur)
	requireOwner(callerAddr)
	if !addr.IsValid() {
		panic("invalid address")
	}
	if addr == owner {
		panic("owner is already a moderator")
	}
	if mods[addr] {
		panic("already a moderator")
	}
	mods[addr] = true
	emit("ModeratorGranted",
		"owner", callerAddr.String(),
		"moderator", addr.String(),
	)
}

// RevokeMod removes a moderator. It does not affect the owner.
func RevokeMod(cur realm, addr address) {
	callerAddr := caller(cur)
	requireOwner(callerAddr)
	if !mods[addr] {
		panic("not a moderator")
	}
	delete(mods, addr)
	emit("ModeratorRevoked",
		"owner", callerAddr.String(),
		"moderator", addr.String(),
	)
}
