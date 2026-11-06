const fs=require('fs');
const raw=fs.readFileSync(process.env.TPL,'utf8');
const m=raw.match(/<!-- LS-ESSAY-BANNER:START -->[\s\S]*?<!-- LS-ESSAY-BANNER:END -->/);
if(!m){console.error('no block');process.exit(1);}
const block=m[0];
const LOGOS=JSON.parse(fs.readFileSync(process.env.LOGOS,'utf8'));
// [name, short, slug, color, lab로고파일(폴백)]
const unis=[
 ['한양대학교','한양대','hanyang','#1D2475','hanyang.png'],
 ['고려대학교','고려대','korea','#862633','korea.png'],
 ['성균관대학교','성균관대','skku','#072A60','skku.png'],
 ['서강대학교','서강대','sogang','#A6192E','sogang.jpeg'],
 ['중앙대학교','중앙대','cau','#2155A4','cau.png'],
 ['경희대학교','경희대','kyunghee','#A40F02','kyunghee.png'],
 ['건국대학교','건국대','konkuk','#006239','konkuk.png'],
 ['인하대학교','인하대','inha','#005BAC','inha.png'],
 ['동국대학교','동국대','dongguk','#EA5514','dongguk.png'],
 ['숭실대학교','숭실대','soongsil','#00587C','soongsil.png'],
 ['광운대학교','광운대','kwangwoon','#7D192D','kwangwoon.png'],
 ['한국외국어대학교','한국외대','hufs','#146E7A','hufs.png'],
 ['숙명여자대학교','숙명여대','sookmyung','#003087','sookmyung.svg'],
 ['서울여자대학교','서울여대','swu','#9E1A20','swu.png'],
 ['한국항공대학교','한국항공대','kau','#002870','kau.png'],
];
const CAMP='essaylab_2026';
function tint(hex){const r=parseInt(hex.slice(1,3),16),g=parseInt(hex.slice(3,5),16),b=parseInt(hex.slice(5,7),16);return `rgba(${r},${g},${b},0.07)`;}
function fill(name,short,slug,color,logoFile){
  const logoSrc = LOGOS[slug] || ('https://lab.legendstudy.com/university-logos/'+logoFile);
  return block
    .replaceAll('{{UNIV_NAME}}',name)
    .replaceAll('{{HEADLINE}}',short+' 논술, 온라인에서 무료로 첨삭받으세요.')
    .replaceAll('{{CTA_LABEL}}',short+' 논술 첨삭받기 →')
    .replaceAll('{{LAB_URL}}','https://lab.legendstudy.com/essay-lab/universities/'+slug+'/')
    .replaceAll('{{UNIV_ID}}',slug).replaceAll('{{POST_ID}}',slug).replaceAll('{{CAMPAIGN_ID}}',CAMP)
    .replaceAll('{{UNIV_COLOR}}',color).replaceAll('{{UNIV_TINT}}',tint(color))
    .replaceAll('{{LOGO_URL}}',logoSrc).replaceAll('{{LOGO_ALT}}',name+' 로고');
}
let out='<!-- =============================================================\n';
out+='     논술 LAB 대학별 홍보 배너 패키지 v3.2 (흰 카드+공식 로고 내장+공식색) · 2026-11-06\n';
out+='     각 대학 게시글 HTML 편집에서 그 대학 블록(START~END)만 복사·붙여넣기.\n';
out+='     로고=공식 로고 base64 내장(12개) / 미전달 3개(중앙·서강·한국항공)=LAB 핫링크.\n';
out+='     ============================================================= -->\n\n';
for(const [name,short,slug,color,logo] of unis){
  out+='<!-- ========== '+name+' ('+slug+' · '+color+') ========== -->\n'+fill(name,short,slug,color,logo)+'\n\n';
}
fs.writeFileSync(process.env.OUT,out);
console.log('wrote',(out.match(/LS-ESSAY-BANNER:START/g)||[]).length,'banners, size',Math.round(out.length/1024)+'KB');
