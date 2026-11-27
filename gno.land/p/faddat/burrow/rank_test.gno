package burrow

import "testing"

func TestHotScoreDecay(t *testing.T) {
	const created int64 = 1_700_000_000
	fresh := HotScore(10, created, created)
	if fresh != 10*HotScale {
		t.Fatalf("fresh score = %d", fresh)
	}
	aged := HotScore(10, created, created+HotHalfLifeSeconds)
	if aged != 5*HotScale {
		t.Fatalf("half-life score = %d", aged)
	}
	// A new 6-point post outranks a 10-point post that is one half-life old.
	if HotScore(6, created, created) <= aged {
		t.Fatal("fresh 6 did not beat aged 10")
	}
	if HotScore(4, created, created) >= aged {
		t.Fatal("fresh 4 beat aged 10")
	}
	// Zero scores tie regardless of age.
	if HotScore(0, created, created) != HotScore(0, created, created+HotHalfLifeSeconds) {
		t.Fatal("zero scores diverged")
	}
	// A positive score, however old, stays above zero.
	if HotScore(1, created, created+HotHalfLifeSeconds*1000) <= 0 {
		t.Fatal("old upvote collapsed to zero or below")
	}
	// Negative scores decay toward zero (they become less negative).
	oldDown := HotScore(-2, created, created+HotHalfLifeSeconds)
	if oldDown != -1*HotScale {
		t.Fatalf("aged downvote = %d", oldDown)
	}
	if oldDown <= HotScore(-2, created, created) {
		t.Fatal("aged downvote did not move toward zero")
	}
	// A clock that sits before creation does not invent negative age.
	if HotScore(3, created, created-100) != 3*HotScale {
		t.Fatal("future creation was penalized")
	}
}
