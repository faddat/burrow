package burrow

const (
	// PageSize is the number of submissions or comments on one gnoweb page.
	PageSize = 20
)

// Window is one page of a list.
type Window struct {
	Page   int
	Pages  int
	Offset int
	Limit  int
}

// Paginate clamps page to the available range and returns the slice window.
// page is 1-based. size below 1 is treated as 1. An empty list yields Pages 0.
func Paginate(page, size, total int) Window {
	if size < 1 {
		size = 1
	}
	if total < 0 {
		total = 0
	}
	pages := 0
	if total > 0 {
		pages = (total + size - 1) / size
	}
	if page < 1 {
		page = 1
	}
	if pages > 0 && page > pages {
		page = pages
	}
	offset := 0
	if page > 1 {
		offset = (page - 1) * size
	}
	if offset > total {
		offset = total
	}
	limit := size
	if offset+limit > total {
		limit = total - offset
	}
	return Window{
		Page:   page,
		Pages:  pages,
		Offset: offset,
		Limit:  limit,
	}
}
