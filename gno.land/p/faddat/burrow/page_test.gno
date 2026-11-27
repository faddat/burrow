package burrow

import "testing"

func TestPaginate(t *testing.T) {
	w := Paginate(1, PageSize, 0)
	if w.Pages != 0 || w.Offset != 0 || w.Limit != 0 || w.Page != 1 {
		t.Fatalf("empty %+v", w)
	}
	w = Paginate(2, 20, 25)
	if w.Page != 2 || w.Pages != 2 || w.Offset != 20 || w.Limit != 5 {
		t.Fatalf("page2 %+v", w)
	}
	w = Paginate(99, 20, 25)
	if w.Page != 2 || w.Offset != 20 {
		t.Fatalf("clamp %+v", w)
	}
	w = Paginate(0, 20, 25)
	if w.Page != 1 || w.Offset != 0 || w.Limit != 20 {
		t.Fatalf("page0 %+v", w)
	}
	w = Paginate(1, 0, 5)
	if w.Limit != 1 || w.Pages != 5 {
		t.Fatalf("size0 %+v", w)
	}
}
