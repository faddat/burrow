# Burrow

Burrow is an on-chain link aggregator for [gno.land](https://gno.land). People submit a link, vote it up or down, and discuss it in a thread. The realm ranks what is hot, new, and top, and gnoweb renders every page as Markdown.

It was inspired by [Jae Kwon asking for an on-chain link aggregator written for gno.land](https://x.com/jaekwon/status/2007456656636903818). Jacob Gadikian is building Burrow as his entry for the [Gnome Tavern hackathon](https://dorahacks.io/hackathon/gnome-tavern/). Submissions close 18 December 2026 01:00 UTC. The entry has to be public, include a real Gno component, and be deployed on the Gno.land Onyx testnet.

## Packages

Development paths, used by `gno test` and `gnodev`:

| Kind | Path |
| --- | --- |
| Pure package | `gno.land/p/faddat/burrow` |
| Realm | `gno.land/r/faddat/burrow` |

Onyx does not yet accept a named namespace such as `faddat`. Address namespaces are permissionless: only that account can publish under `gno.land/r/<g1-address>/...`. [`scripts/deploy-onyx.sh`](scripts/deploy-onyx.sh) copies the packages and rewrites `faddat` to the signing key's address before `addpkg`. See [Users and teams](https://github.com/gnolang/gno/blob/master/docs/resources/users-and-teams.md).

## Architecture

`gno.land/p/faddat/burrow` is immutable logic with no realm state:

- URL, title, and text checks
- hot score
- page windows
- gnoweb `$help` transaction links

`gno.land/r/faddat/burrow` holds the board. Exported functions take `cur realm` and are called with `cross`, which is the current interrealm convention. A direct user call is required (`cur.Previous().IsUserCall()`), so another contract cannot submit or vote under a second identity. The signer is `cur.Previous().Address()`.

State is package-level data: submissions, comments, one vote record per address per target, a URL index, profiles, the owner, and moderators. Writes emit `chain.Emit` events: `ItemSubmitted`, `ItemVoted`, `CommentSubmitted`, `CommentVoted`, hide, unhide, and remove for items and comments, plus `OwnershipClaimed`, `OwnershipTransferred`, `ModeratorGranted`, and `ModeratorRevoked`. An unchanged vote does not emit.

`Render(path)` returns Markdown for gnoweb.

| Path | Page |
| --- | --- |
| `/` and `/hot` | hot ranking |
| `/new` | newest first |
| `/top` | highest score, then newer |
| `/item/<id>` | submission, thread, vote and reply links |
| `/user/<addr>` | karma, submissions, comments |
| `/submit` | field rules and a `gnokey` example |

Listings and the item page link to `$help` so a reader can sign the call with Adena from gnoweb. Example: `/r/faddat/burrow$help&func=VoteItem&dir=1&id=7`.

### Ranking

Hot score is an integer computed at render time from the block time (`time.Now()`, which is deterministic on chain):

```
weight = 1_000_000 * halfLife / (halfLife + ageSeconds)
hot    = score * weight
```

The half-life is 6 hours. A newer item wins a tie. A negative score decays toward zero, so an old downvote fades. New is creation order. Top is raw `up - down`, then newer id. Hidden and removed submissions stay out of the lists. The sort walks every visible id, which is the right size for a hackathon board and worth revisiting if the board grows large.

### Rules

- Title: 4 to 120 characters, no control characters. Text is optional, up to 4000 bytes. A comment is 1 to 2000 characters.
- URL: `http` or `https` only. The host is lowercased, the fragment and a trailing slash are dropped, and default ports 80 and 443 are dropped. A second live submission of the same URL is refused. Removing a submission frees the URL. Hiding it does not.
- One vote per address per submission or comment. `dir` is `1`, `-1`, or `0` (clear). Voting the same way again changes nothing. You cannot vote on your own submission or comment.
- Karma moves by the vote delta on the author. Removing a submission or comment reverses that item's net score. Hiding does not.
- The same address may submit or comment at most once every 20 blocks. Votes are not rate limited. The owner and moderators are exempt.
- Threads nest up to 6 levels, with at most 200 comments on one submission.
- The realm starts unowned. The first `Claim` becomes the owner and can `TransferOwnership`, `GrantMod`, and `RevokeMod`. The owner and moderators can hide, unhide, and remove submissions and comments. A hidden or removed target cannot be voted.

## Develop

Install `gno`, `gnokey`, and `gnodev` from [gnolang/gno](https://github.com/gnolang/gno) master. This repository is written against commit `58af98ed7956844df743c12f26834c5a1d3468e4` and Go 1.25. CI installs that same commit.

```sh
git clone https://github.com/gnolang/gno.git
cd gno
git checkout 58af98ed7956844df743c12f26834c5a1d3468e4
make install.gno install.gnokey install.gnodev
export PATH="$(go env GOPATH)/bin:$PATH"
```

From this repository:

```sh
make test
make lint
```

`gnowork.toml` at the root lets the two packages resolve each other.

### Local chain

`gnodev` starts a single-node chain (chain id `dev`) and gnoweb. From the repository root:

```sh
gnodev ./gno.land/p/faddat/burrow ./gno.land/r/faddat/burrow
```

Open http://127.0.0.1:8888/r/faddat/burrow . Keys already in the local keybase are prefunded, including the built-in `devtest` account (`g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5`). RPC is `http://127.0.0.1:26657`. These defaults are from the [gnodev](https://github.com/gnolang/gno/blob/master/docs/resources/gnodev.md) and [getting started](https://github.com/gnolang/gno/blob/master/docs/builders/getting-started.md) docs.

### Walkthrough

Create a second key if you want a voter who is not the author. `devtest` can post; another key can vote.

```sh
gnokey add bob
```

Submit, then vote and reply. The author cannot vote on their own post.

```sh
gnokey maketx call \
  -pkgpath "gno.land/r/faddat/burrow" \
  -func Submit \
  -args "A clear title" \
  -args "https://example.com/story" \
  -args "optional note" \
  -gas-fee 10000ugnot -gas-wanted 10000000 \
  -chainid dev -remote http://127.0.0.1:26657 \
  devtest

gnokey maketx call \
  -pkgpath "gno.land/r/faddat/burrow" \
  -func VoteItem \
  -args 1 \
  -args 1 \
  -gas-fee 10000ugnot -gas-wanted 10000000 \
  -chainid dev -remote http://127.0.0.1:26657 \
  bob

gnokey maketx call \
  -pkgpath "gno.land/r/faddat/burrow" \
  -func Comment \
  -args 1 \
  -args 0 \
  -args "worth reading" \
  -gas-fee 10000ugnot -gas-wanted 10000000 \
  -chainid dev -remote http://127.0.0.1:26657 \
  bob
```

`Comment` arguments are item id, parent comment id (`0` for the top), and body. Reload the front page, `/new`, `/top`, `/item/1`, and `/user/<address>`.

The same calls are linked from the pages. On gnoweb, open **Actions** or follow a `$help` link and sign with [Adena](https://github.com/gnolang/gno/blob/master/docs/users/third-party-wallets.md).

Claim the board, then appoint a moderator:

```sh
gnokey maketx call \
  -pkgpath "gno.land/r/faddat/burrow" \
  -func Claim \
  -gas-fee 10000ugnot -gas-wanted 10000000 \
  -chainid dev -remote http://127.0.0.1:26657 \
  devtest

gnokey maketx call \
  -pkgpath "gno.land/r/faddat/burrow" \
  -func GrantMod \
  -args g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec \
  -gas-fee 10000ugnot -gas-wanted 10000000 \
  -chainid dev -remote http://127.0.0.1:26657 \
  devtest
```

Replace the address with the moderator's `g1` address. `HideItem`, `UnhideItem`, and `RemoveItem` take the submission id. The comment variants take the comment id.

Read a page without spending gas:

```sh
gnokey query vm/qrender \
  -data "gno.land/r/faddat/burrow:" \
  -remote http://127.0.0.1:26657
```

## Deploy to Onyx

This repository is not deployed. There is no key in the development environment. Jacob runs the script with his own key name:

```sh
scripts/deploy-onyx.sh <gnokey-key-name>
```

Official network values, from [Gno networks](https://github.com/gnolang/gno/blob/master/docs/resources/gnoland-networks.md) and [Getting started](https://github.com/gnolang/gno/blob/master/docs/builders/getting-started.md):

| | |
| --- | --- |
| Chain id | `onyx-1` |
| RPC | `https://rpc.onyx.testnets.gno.land:443` |
| Current-testnet alias | `https://rpc.latest.testnets.gno.land:443` |
| Faucet | https://faucet.gno.land |
| gnoweb | https://onyx.testnets.gno.land and https://latest.testnets.gno.land |

The script does the equivalent of the documented `addpkg` and `call` transactions. Gas meets the floor of 1 ugnot per 1000 gas. Deploy uses `-gas-wanted 20000000 -gas-fee 20000ugnot -max-deposit 20000000ugnot`. `Claim` uses `-gas-wanted 10000000 -gas-fee 10000ugnot -max-deposit 5000000ugnot`. A first `Submit` on a fresh realm used about 7.3 million gas in a local run, so the call cap sits above that.

Before running it:

1. Install `gnokey` from the same gno commit as above.
2. Import or create the key: `gnokey add <key-name>` (or `--recover`).
3. Fund that address at https://faucet.gno.land on Onyx.
4. Confirm the balance:

```sh
gnokey query bank/balances/<g1-address> \
  -remote https://rpc.onyx.testnets.gno.land:443
```

The script prints the package paths and the gnoweb URL when `Claim` succeeds. Set `GNO_PASSWORD` only if you accept passing the key password on stdin (`--insecure-password-stdin`). Otherwise the script prompts.

Equivalent commands, with the address filled in, are:

```sh
gnokey maketx addpkg \
  -pkgpath "gno.land/p/<g1-address>/burrow" \
  -pkgdir <staged pure package> \
  -gas-fee 20000ugnot -gas-wanted 20000000 -max-deposit 20000000ugnot \
  -chainid onyx-1 -remote https://rpc.onyx.testnets.gno.land:443 \
  <key-name>

gnokey maketx addpkg \
  -pkgpath "gno.land/r/<g1-address>/burrow" \
  -pkgdir <staged realm> \
  -gas-fee 20000ugnot -gas-wanted 20000000 -max-deposit 20000000ugnot \
  -chainid onyx-1 -remote https://rpc.onyx.testnets.gno.land:443 \
  <key-name>

gnokey maketx call \
  -pkgpath "gno.land/r/<g1-address>/burrow" \
  -func Claim \
  -gas-fee 10000ugnot -gas-wanted 10000000 -max-deposit 5000000ugnot \
  -chainid onyx-1 -remote https://rpc.onyx.testnets.gno.land:443 \
  <key-name>
```

The staged directories are the production `.gno` files and `gnomod.toml` only, with `faddat` rewritten to `<g1-address>`. Deploy the pure package first and wait until it answers `vm/qfile`. Then deploy the realm and wait until `vm/qrender` answers. Onyx turns a new package on a few seconds after `addpkg`. If it stays parked, look the path up at https://gpas.latest.testnets.gno.land . `enablepkg` is for approvers; the script does not send it.

After `Claim`, the board is at:

```
https://onyx.testnets.gno.land/r/<g1-address>/burrow
```

## License

[MIT](LICENSE).
