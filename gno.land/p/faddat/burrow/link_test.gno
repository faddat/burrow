package burrow

import "testing"

func TestTxLink(t *testing.T) {
	got := TxLink("/r/faddat/burrow", "Submit")
	want := "/r/faddat/burrow$help&func=Submit"
	if got != want {
		t.Fatalf("got %s", got)
	}
	got = TxLink("/r/faddat/burrow/", "VoteItem", "id", "7", "dir", "-1")
	want = "/r/faddat/burrow$help&func=VoteItem&dir=-1&id=7"
	if got != want {
		t.Fatalf("got %s", got)
	}
	got = TxLink("/r/faddat/burrow", "Comment", "body", "hello world")
	if got != "/r/faddat/burrow$help&func=Comment&body=hello+world" {
		t.Fatalf("got %s", got)
	}
}

func TestTxLinkRejectsOddArgs(t *testing.T) {
	defer func() {
		if recover() == nil {
			t.Fatal("expected panic")
		}
	}()
	TxLink("/r/faddat/burrow", "Submit", "title")
}
