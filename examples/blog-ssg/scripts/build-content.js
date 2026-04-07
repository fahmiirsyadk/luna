const fs = require('fs');
const path = require('path');
const fm = require('front-matter');
const MarkdownIt = require('markdown-it');
const mkdirp = require('mkdirp');

const contentDir = path.join(__dirname, '../content/posts');
const outputDir = path.join(__dirname, '../generated');

mkdirp.sync(outputDir);

const md = new MarkdownIt({
  html: true,
  linkify: true,
  typographer: true,
});

const files = fs.readdirSync(contentDir).filter(f => f.endsWith('.md'));

const posts = files.map(file => {
  const content = fs.readFileSync(path.join(contentDir, file), 'utf-8');
  const { attributes, body } = fm(content);
  const bodyHtml = md.render(body);
  
  const slug = attributes.slug || file.replace('.md', '');
  
  return {
    slug,
    title: attributes.title,
    date: attributes.date,
    description: attributes.description || '',
    draft: attributes.draft || false,
    bodyHtml,
  };
}).filter(p => !p.draft);

posts.sort((a, b) => new Date(b.date) - new Date(a.date));

fs.writeFileSync(
  path.join(outputDir, 'posts.json'),
  JSON.stringify(posts, null, 2)
);

console.log(`Generated ${posts.length} posts to ${outputDir}/posts.json`);
