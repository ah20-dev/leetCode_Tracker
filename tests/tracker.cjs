const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
(async () => {
 const browser = await chromium.launch({headless:true,channel:"chrome"});
 try {
 const page=await browser.newPage({viewport:{width:1280,height:950}});
 await page.clock.setFixedTime(new Date('2026-10-16T18:00:00Z'));
 const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('dialog',d=>d.accept());
 await page.addInitScript(() => {
  if(!localStorage.getItem('test-seeded')){
   localStorage.setItem('test-seeded','1');
   localStorage.setItem('test-progress',JSON.stringify({version:1,items:{'nc-1':{status:'done',notes:'keep NC note'},'bb-PairInArray':{status:'todo',notes:'keep BB note'}}}));
  }
  window.prompt=(prompt,raw)=>{
   const {command,value}=JSON.parse(raw);
   if(command==='load')return JSON.stringify({value:localStorage.getItem('test-progress')});
   if(command==='save'){
    if(window.failSave)return JSON.stringify({error:'Test disk failure'});
    localStorage.setItem('test-progress',value);return '{"value":true}';
   }
   if(command==='export'){window.exported=value;return '{"value":true}';}
  };
 });
 await page.goto(pathToFileURL(path.resolve('LeetCode Tracker.app/Contents/Resources/tracker.html')).href);
 const row=id=>page.locator(`.row[data-id="${id}"]`);
 const status=async id=>await row(id).locator('[data-act=status]').getAttribute('class');
 const clickStatus=async id=>row(id).locator('[data-act=status]').evaluate(el=>el.click());
 const saved=()=>page.evaluate(()=>JSON.parse(localStorage.getItem('test-progress')));
 assert.equal(await page.locator('#tabbtn-bb').textContent(),'Custom List');
 assert.equal(await page.locator('#tab-bb h2').textContent(),'Custom List');
 assert.equal(await page.locator('[data-act=bb]').first().textContent(),'problem details');
 assert.equal(await page.locator('#additional-cats .row').count(),107);
 assert.equal(await page.locator('#lists .row').count(),380);
 for(const id of ['nc-1','additional-1','bb-PairInArray','bb-DoTheyAddUp'])assert.match(await status(id),/st-done/);
 assert.equal(await row('nc-1').locator('textarea').inputValue(),'keep NC note');
 assert.equal(await row('bb-PairInArray').locator('textarea').inputValue(),'keep BB note');
 await clickStatus('bb-PairInArray');
 for(const id of ['nc-1','additional-1','bb-PairInArray','bb-DoTheyAddUp'])assert.match(await status(id),/st-todo/);
 await clickStatus('additional-1');await clickStatus('additional-1');
 for(const id of ['nc-1','additional-1','bb-PairInArray','bb-DoTheyAddUp'])assert.match(await status(id),/st-done/);
 await page.reload(); assert.match(await status('nc-1'),/st-done/);
 assert.equal(await page.locator('#daily-count').textContent(),'1 completed');
 // Distinct LeetCode IDs in a Bloomberg row must never collapse into one identity.
 await clickStatus('nc-242');await clickStatus('nc-242');
 assert.match(await status('additional-242'),/st-done/);
 assert.equal(await page.locator('#daily-count').textContent(),'2 completed');
 assert.match(await status('nc-49'),/st-todo/);
 assert.match(await status('bb-Anagram'),/st-prog/);
 assert.match(await row('bb-Anagram').locator('[data-key="lc-242"]').getAttribute('class'),/st-done/);
 await row('bb-Anagram').locator('[data-key="lc-49"]').evaluate(el=>{el.click();el.click();});
 assert.match(await status('bb-Anagram'),/st-done/);assert.match(await status('additional-49'),/st-done/);
 await clickStatus('bb-Anagram');
 assert.match(await status('nc-242'),/st-todo/);assert.match(await status('additional-49'),/st-todo/);
 assert.equal(await page.locator('#daily-count').textContent(),'1 completed');
 // An additional-only problem, notes, filters, and category/total progress.
 await page.locator('#tabbtn-additional').click();await page.locator('#search').fill('#438');
 assert.equal(await page.locator('#matchcount').textContent(),'1 of 107');
 await clickStatus('additional-438');await clickStatus('additional-438');
 await row('additional-438').locator('[data-act=note]').click();
 await row('additional-438').locator('textarea').fill('new PDF problem note');
 assert.equal((await saved()).items['additional-438'].notes,'new PDF problem note');
 await page.locator('#statusfilter').selectOption('done');
 assert.equal(await page.locator('#matchcount').textContent(),'1 of 107');
 await page.locator('#statusfilter').selectOption('todo');assert.equal(await page.locator('#matchcount').textContent(),'0 of 107');
 await page.locator('#statusfilter').selectOption('all');await page.locator('#search').fill('');
 await page.locator('#dl-btn').click();const exported=await page.evaluate(()=>window.exported);
 assert.equal(JSON.parse(exported).version,2);
 await page.locator('#reset-btn').click();assert.match(await status('nc-1'),/st-todo/);
 await page.locator('#import-file').setInputFiles({name:'backup.json',mimeType:'application/json',buffer:Buffer.from(exported)});
 await page.waitForFunction(()=>document.querySelector('[data-id="nc-1"] .st').classList.contains('st-done'));
 assert.match(await status('additional-1'),/st-done/);
 assert.equal(await row('additional-438').locator('textarea').inputValue(),'new PDF problem note');
 // Import legacy subsets updates all matching rows and leaves unrelated notes intact.
 await page.locator('#import-file').setInputFiles({name:'old.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify({version:1,items:{'bb-PairInArray':{status:'todo',notes:'imported BB note'}}}))});
 await page.waitForFunction(()=>document.querySelector('[data-id="nc-1"] .st').classList.contains('st-todo'));
 assert.match(await status('additional-1'),/st-todo/);
 assert.equal(await row('nc-1').locator('textarea').inputValue(),'keep NC note');
 await page.reload();assert.match(await status('additional-438'),/st-done/);
 await page.locator('#tabbtn-additional').click();
 await page.screenshot({path:'tmp/additional-problems.png',fullPage:true});
 await page.evaluate(()=>window.failSave=true);await clickStatus('additional-438');
 assert.match(await page.locator('#local-save-status').textContent(),/Not saved/);
 assert.equal((await saved()).sharedStatus['lc-438'].status,'done');
 assert.deepEqual(errors,[]);
 console.log('PASS: 107 PDF problems; legacy migration; three-tab status sync and undo; multiple Bloomberg mappings; notes; reload; filters; export/import/reset; save failure reporting.');
 } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exit(1);});
