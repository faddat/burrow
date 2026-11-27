package burrow

const (
	// HotHalfLifeSeconds is the age at which a score is worth half as much.
	// Ranking uses this with the block time so the order is the same for
	// every caller at a given block.
	HotHalfLifeSeconds int64 = 6 * 3600
	// HotScale keeps the decayed score in integer space.
	HotScale int64 = 1_000_000
)

// HotScore ranks a submission for the front page.
// A higher result sorts first. score is upvotes minus downvotes and may be
// negative. createdUnix and nowUnix are Unix seconds from the chain clock
// (time.Now at submission, and time.Now while rendering).
//
// The weight is HotScale at age 0 and half of that one half-life later:
//
//	weight = HotScale * halfLife / (halfLife + age)
//	hot    = score * weight
//
// Zero scores tie. Callers should break ties with the newer id first.
// Negative scores decay toward zero, so an old downvote loosens its hold.
func HotScore(score int, createdUnix, nowUnix int64) int64 {
	age := nowUnix - createdUnix
	if age < 0 {
		age = 0
	}
	weight := HotScale * HotHalfLifeSeconds / (HotHalfLifeSeconds + age)
	if weight < 1 && score != 0 {
		weight = 1
	}
	return int64(score) * weight
}
