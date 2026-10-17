const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('LeetCode Tracker.app/Contents/Resources/tracker.html','utf8');
const script=html.match(/<script>([\s\S]*?)<\/script>/)[1];new Function(script);
const ctx={state:{sharedStatus:{}},validKeys:{'lc-1':true,'lc-2':true,'bb-custom':true}};
vm.createContext(ctx);
vm.runInContext(script.slice(script.indexOf('function dailySummary('),script.indexOf('function updateDailyTracker(')),ctx);
const set=(key,at,status='done')=>ctx.state.sharedStatus[key]={status,updatedAt:at};
const count=at=>ctx.dailySummary(Date.parse(at)).count;
set('lc-1','2026-10-16T13:59:59Z'); // Before 8 AM CST still counts.
assert.equal(count('2026-10-16T14:00:00Z'),1);
assert.equal(count('2026-10-17T13:59:58.999Z'),1);
assert.equal(count('2026-10-17T13:59:59Z'),0); // Expires exactly 24 hours later.
set('lc-1','2026-10-17T05:59:59Z');
assert.equal(count('2026-10-17T06:00:00Z'),1); // No CST midnight reset.
set('lc-2','2026-10-17T06:00:00Z');
assert.equal(count('2026-10-17T06:00:00Z'),2);
set('lc-2','2026-10-17T06:00:00Z','todo');
assert.equal(count('2026-10-17T06:00:00Z'),1);
set('bb-custom','2026-10-17T05:30:00Z');
assert.equal(count('2026-10-17T06:00:00Z'),2);
set('lc-1','invalid');assert.equal(count('2026-10-17T06:00:00Z'),1);
set('lc-2','2026-10-17T07:00:00Z');assert.equal(count('2026-10-17T06:00:00Z'),1);
set('lc-1','2026-12-16T14:00:00Z');assert.equal(count('2026-12-17T13:59:59Z'),1);
assert.equal(count('2026-12-17T14:00:00Z'),0);
console.log('PASS: rolling 24-hour expiration, no 8 AM/midnight reset, undo, custom problems, invalid/future timestamps, summer/winter.');
