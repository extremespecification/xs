#!/usr/bin/env python3
"""digest: turn Claude Code transcripts into chunks a reader agent can go through, plus a few numbers.

For each session (~/.claude/projects/<project>/<session>.jsonl) it keeps the title, the time span, tool counts,
the subagents spawned (type/model/effort: description) and every prompt the owner typed. Teammate reports are kept,
labelled and capped; compaction summaries are only counted. Subagents' own transcripts are skipped.

The same session can sit under several config dirs (a session copied or resumed under another account): pass each
with --projects. A prompt repeated with its timestamp (a copy, a fork) is counted once.

  python3 digest.py --out DIR [--projects DIR ...] [--match SUBSTR ...] [--since YYYY-MM-DD] [--chunk-kb 180] [--cap 600]
  python3 digest.py --selftest
"""
import argparse, collections, json, os, re, statistics, sys, tempfile

TEAMMATE = 'Another Claude session sent a message'
SUMMARY = 'This session is being continued from a previous conversation'
NOISE = ('<local-command', 'Caveat:', '<system-reminder>', '<task-notification>', '<bash-', '<user-prompt-submit-hook>')
IMAGE = re.compile(r'\[Image #\d+\]')


def text(content):
    if isinstance(content, str):
        return content
    return '\n'.join(x.get('text', '') for x in content or [] if isinstance(x, dict) and x.get('type') == 'text')


def read_session(path):
    s = dict(title=None, start=None, end=None, items=[], summaries=0, interrupts=0, auto=0,
             tools=collections.Counter(), agents=[])
    for line in open(path, errors='ignore'):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        if o.get('type') == 'ai-title':
            s['title'] = o.get('aiTitle') or o.get('title') or s['title']
        ts = o.get('timestamp')
        if ts:
            s['start'] = s['start'] or ts
            s['end'] = ts
        if o.get('isSidechain'):
            continue
        msg = o.get('message') or {}
        if o.get('type') == 'user' and o.get('entrypoint') == 'sdk-cli':  # claude -p: a script typed it, not the owner
            s['auto'] += 1
        elif o.get('type') == 'user' and not o.get('isMeta'):
            t = text(msg.get('content')).strip()
            cmd = re.search(r'<command-name>(/[^<]+)</command-name>(?:.*?<command-args>(.*?)</command-args>)?', t, re.S)
            if not t:
                continue
            if '[Request interrupted by user' in t:
                s['interrupts'] += 1
            elif t.startswith(TEAMMATE):
                s['items'].append((ts, 'teammate', t[len(TEAMMATE):].lstrip(': \n')))
            elif t.startswith(SUMMARY):
                s['summaries'] += 1
            elif cmd:
                s['items'].append((ts, 'owner', f"{cmd[1]} {(cmd[2] or '').strip()}".strip()))
            elif not t.startswith(NOISE):
                s['items'].append((ts, 'owner', t))
        elif o.get('type') == 'assistant':
            for x in msg.get('content') or []:
                if isinstance(x, dict) and x.get('type') == 'tool_use':
                    s['tools'][x.get('name')] += 1
                    if x.get('name') in ('Agent', 'Task'):
                        i = x.get('input') or {}
                        s['agents'].append(f"{i.get('subagent_type', '-')}/{i.get('model', '-')}/{i.get('effort', '-')}: {i.get('description', '')}")
    return s


def render(sid, s, cap):
    owner = sum(1 for _, who, _ in s['items'] if who == 'owner')
    mates = len(s['items']) - owner
    out = [f"=== {sid} | {s['title']} | {s['start']} -> {s['end']} | owner prompts={owner} teammate reports={mates} "
           f"interrupts={s['interrupts']} compactions={s['summaries']}",
           'tools: ' + ', '.join(f'{k}={v}' for k, v in s['tools'].most_common(12))]
    if s['agents']:
        out.append('agents: ' + ' | '.join(s['agents'][:30]))
    for ts, who, t in s['items']:
        limit = cap if who == 'owner' else cap // 2
        t = t if len(t) <= limit else t[:limit] + f' ...[+{len(t) - limit} chars]'
        out.append(f"[{(ts or '')[:16]}] {'' if who == 'owner' else 'TEAMMATE: '}{t}")
    return '\n'.join(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', required=True)
    ap.add_argument('--projects', action='append', default=[])
    ap.add_argument('--match', action='append', default=[])
    ap.add_argument('--since', default='')
    ap.add_argument('--chunk-kb', type=int, default=180)
    ap.add_argument('--cap', type=int, default=600)
    a = ap.parse_args(argv)
    home = os.path.expanduser('~').replace('/', '-') + '-'

    found, auto = {}, 0
    for root in a.projects or [os.path.expanduser('~/.claude/projects')]:
        for proj in sorted(os.listdir(root)):
            pdir = os.path.join(root, proj)
            if not os.path.isdir(pdir) or (a.match and not any(m in proj for m in a.match)):
                continue
            for f in os.listdir(pdir):
                if f.endswith('.jsonl'):
                    s = read_session(os.path.join(pdir, f))
                    auto += s['auto']
                    if s['items'] and (s['start'] or '') >= a.since:
                        prev = found.get((proj, f))
                        if prev:  # ponytail: keeps the larger copy's tools and agents, adds the other's prompts
                            s, other = (s, prev) if len(s['items']) >= len(prev['items']) else (prev, s)
                            s['items'] = sorted(set(s['items']) | set(other['items']), key=lambda x: x[0] or '')
                            s['start'], s['end'] = min(s['start'], other['start']), max(s['end'], other['end'])
                        found[(proj, f)] = s
    sessions = [(proj.removeprefix(home), f[:8], s) for (proj, f), s in found.items()]
    sessions.sort(key=lambda x: (x[2]['start'] or '', -len(x[2]['items'])))
    seen = set()  # a forked session repeats its parent's prompts with their timestamps: count them once
    for _, _, s in sessions:
        s['items'] = [x for x in s['items'] if x not in seen]
        seen.update(s['items'])
    sessions = [x for x in sessions if x[2]['items']]
    sessions.sort(key=lambda x: (x[0], x[2]['start'] or ''))

    os.makedirs(os.path.join(a.out, 'chunks'), exist_ok=True)
    chunk, n, last = '', 0, None
    for proj, sid, s in sessions:
        block = ('' if proj == last else f'## {proj}\n') + render(sid, s, a.cap) + '\n\n'
        if chunk and len(chunk) + len(block) > a.chunk_kb * 1024:
            open(os.path.join(a.out, 'chunks', f'chunk-{n:02}.txt'), 'w').write(chunk)
            chunk, n, block = '', n + 1, f'## {proj}\n' + block.removeprefix(f'## {proj}\n')
        chunk, last = chunk + block, proj
    if chunk:
        open(os.path.join(a.out, 'chunks', f'chunk-{n:02}.txt'), 'w').write(chunk)
        n += 1

    prompts = [t for _, _, s in sessions for _, who, t in s['items'] if who == 'owner']
    bare = [IMAGE.sub('', p).strip().lower() for p in prompts]
    lengths = sorted(len(p) for p in bare) or [0]
    models = collections.Counter(x.split(':')[0] for _, _, s in sessions for x in s['agents'])
    lines = [
        f'sessions: {len(sessions)} in {len({p for p, _, _ in sessions})} projects',
        f'owner prompts: {len(prompts)}, median {statistics.median(lengths):.0f} chars, '
        f'p90 {lengths[int(len(lengths) * .9)]} chars',
        f'with a screenshot: {sum(1 for p in prompts if IMAGE.search(p)) * 100 // max(len(prompts), 1)}%',
        f"teammate reports: {sum(1 for _, _, s in sessions for _, w, _ in s['items'] if w == 'teammate')}",
        f"interrupts: {sum(s['interrupts'] for _, _, s in sessions)}, compactions: {sum(s['summaries'] for _, _, s in sessions)}",
        f'skipped: {auto} messages sent by claude -p',
        f'chunks: {n} in {os.path.join(a.out, "chunks")}',
        '', 'commonest short prompts:',
        *(f'  {c:5}  {p}' for p, c in collections.Counter(p for p in bare if 0 < len(p) < 25).most_common(40)),
        '', 'subagents by type/model/effort:',
        *(f'  {c:5}  {m}' for m, c in models.most_common(20)),
    ]
    open(os.path.join(a.out, 'stats.txt'), 'w').write('\n'.join(lines) + '\n')
    print('\n'.join(lines[:6]))


def selftest():
    with tempfile.TemporaryDirectory() as d:
        proj = os.path.join(d, 'projects', '-Users-x-Code-app')
        os.makedirs(proj)
        rows = [
            {'type': 'ai-title', 'aiTitle': 'Fix the table'},
            {'type': 'user', 'timestamp': '2026-11-01T10:00:00Z', 'message': {'content': '[Image #1] the table overflows, fix it'}},
            {'type': 'assistant', 'message': {'content': [{'type': 'tool_use', 'name': 'Agent', 'input': {
                'subagent_type': 'general-purpose', 'model': 'sonnet', 'description': 'fix table'}}]}},
            {'type': 'user', 'timestamp': '2026-11-01T10:05:00Z', 'message': {'content': TEAMMATE + ':\n<teammate-message>done, not seen in a browser</teammate-message>'}},
            {'type': 'user', 'timestamp': '2026-11-01T10:06:00Z', 'message': {'content': SUMMARY + '. Summary...'}},
            {'type': 'user', 'isSidechain': True, 'message': {'content': 'a subagent prompt, not the owner'}},
            {'type': 'user', 'timestamp': '2026-11-01T10:07:00Z', 'message': {'content': [{'type': 'text', 'text': 'commit'}]}},
            {'type': 'user', 'timestamp': '2026-11-01T10:08:00Z', 'message': {'content': '<command-name>/compact</command-name><command-args></command-args>'}},
        ]
        with open(os.path.join(proj, 'abcdef12-0000.jsonl'), 'w') as f:
            f.write('\n'.join(json.dumps(r) for r in rows) + '\nnot json\n')
        with open(os.path.join(proj, 'fork0000-0000.jsonl'), 'w') as f:
            f.write('\n'.join(json.dumps(r) for r in rows[:2]) + '\n')
        with open(os.path.join(proj, 'script00-0000.jsonl'), 'w') as f:
            f.write(json.dumps({**rows[1], 'entrypoint': 'sdk-cli', 'timestamp': '2026-11-01T11:00:00Z'}) + '\n')
        copy = os.path.join(d, 'projects-g', '-Users-x-Code-app')
        os.makedirs(copy)
        more = {'type': 'user', 'timestamp': '2026-11-01T10:09:00Z', 'message': {'content': 'resumed here'}}
        with open(os.path.join(copy, 'abcdef12-0000.jsonl'), 'w') as f:
            f.write('\n'.join(json.dumps(r) for r in rows[:-1] + [more]) + '\n')
        main(['--projects', os.path.join(d, 'projects'), '--projects', os.path.join(d, 'projects-g'),
              '--out', os.path.join(d, 'out')])
        stats = open(os.path.join(d, 'out', 'stats.txt')).read()
        chunk = open(os.path.join(d, 'out', 'chunks', 'chunk-00.txt')).read()
        assert 'sessions: 1 ' in stats and 'owner prompts: 4' in stats, stats
        assert 'with a screenshot: 25%' in stats, stats
        assert 'skipped: 1 messages' in stats, stats
        assert 'teammate reports: 1' in stats and 'compactions: 1' in stats, stats
        assert 'general-purpose/sonnet/-' in stats, stats
        assert 'TEAMMATE: <teammate-message>done' in chunk and 'not the owner' not in chunk, chunk
        assert chunk.count('resumed here') == 1 and chunk.count('commit') == 1 and '/compact' in chunk, chunk
        assert '| Fix the table |' in chunk and '] /compact' in chunk, chunk
    print('digest selftest: ok')


if __name__ == '__main__':
    selftest() if sys.argv[1:] == ['--selftest'] else main()
