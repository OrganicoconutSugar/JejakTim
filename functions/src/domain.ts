import {z} from 'zod';
export const id = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);
export const text = (max=2000) => z.string().trim().min(3).max(max);
export const date = z.iso.datetime({offset:true});
export const evidenceUrl = z.string().max(2048).refine(value => {
  try { const u=new URL(value);return u.protocol==='https:'&&u.hostname.includes('.')&&!u.username&&!u.password; } catch {return false;}
},'Gunakan tautan HTTPS yang valid.');
export const insightSchema=z.strictObject({
  summary:text(1200),
  teamSignals:z.array(z.strictObject({type:z.enum(['deadline_risk','blocked_task','review_waiting','workload_visibility','positive_progress']),observation:text(700),evidenceTaskIds:z.array(id).max(20)})).max(8),
  recommendations:z.array(z.strictObject({title:text(160),rationale:text(700),actionType:z.enum(['open_task','discuss_with_team','update_deadline','request_help','review_submission']),targetTaskIds:z.array(id).max(20)})).max(8),
  limitations:z.array(text(400)).min(1).max(8),
});
export function validateInsight(value:unknown,taskIds:Set<string>) {
  const result=insightSchema.parse(value);
  for(const signal of result.teamSignals)for(const tid of signal.evidenceTaskIds)if(!taskIds.has(tid))throw new Error('Unknown evidence task');
  for(const action of result.recommendations)for(const tid of action.targetTaskIds)if(!taskIds.has(tid))throw new Error('Unknown recommendation task');
  const banned=/malas|pemalas|free.?rider|kepribadian|peringkat anggota|skor produktivitas|tidak berkontribusi/i;
  if(banned.test(JSON.stringify(result)))throw new Error('Unsupported judgment');
  return result;
}
export interface InsightAdapter { analyze(aggregate:Readonly<Record<string,unknown>>):Promise<unknown>; }
export class UnconfiguredInsightAdapter implements InsightAdapter {
  async analyze():Promise<never>{throw new Error('AI_UNAVAILABLE');}
}
export type Row=Record<string,any>;
export function aggregate(tasks:Row[],now=new Date()) {
  return {total:tasks.length,done:tasks.filter(t=>t.status==='done').length,review:tasks.filter(t=>t.status==='submitted').length,overdue:tasks.filter(t=>!['done','cancelled'].includes(t.status)&&t.dueAt&&new Date(t.dueAt)<now).length};
}
export function maySubmit(task:Row,uid:string){return task.assigneeIds.includes(uid)&&['in_progress','revision_requested'].includes(task.status);}
export function mayReview(task:Row,submission:Row,uid:string){return task.reviewerId===uid&&submission.submittedBy!==uid&&task.status==='submitted'&&submission.status==='pending_review';}
