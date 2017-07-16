const fs = require('fs');
const glob = require('glob');
const path = require('path');
const mustache = require('mustache');
const toc = require('markdown-toc');
const parseComments = require('parse-comments');

/**
 * Read each file and call `parse-comments` on it.
 *
 * @param  {String|Array} files List of file paths to read from.
 * @return {Object|Array}       Array of `parse-comments` objects.
 */
const parseFiles = files => {
  let response = [];
  files.forEach(file => {
    const f = fs.readFileSync(file, 'utf8');
    response = response.concat(parseComments(f));
  });

  return response;
};

/**
 * Filters/sorts the results from `parse-comments`.
 * @param  {Object|Array} comments Array of `parse-comments` objects.
 * @return {Object}                Filtered comments sorted by `@api` and `@category`.
 */
const processComments = comments => {
  let sorted = {};

  comments.forEach(comment => {
    if (typeof comment.api === 'undefined') return;

    // Store the object based on its api (ie. requests, events) and category (ie. general, scenes, etc).
    comment.category = comment.category || 'miscellaneous';
    sorted[comment.api] = sorted[comment.api] || {};
    sorted[comment.api][comment.category] = sorted[comment.api][comment.category] || [];

    sorted[comment.api][comment.category].push(comment);
  });

  let resp = {};

  // Switch the format to something mustache compatible, an array of category objects.
  Object.keys(sorted).forEach(api => {
    resp[api] = [];
    Object.keys(sorted[api]).forEach(category => {
      resp[api].push({
        category,
        items: sorted[api][category]
      });
    });
  });

  return resp;
};

/**
 * Bind mustache helper functions to the data object.
 */
const bindMustacheHelpers = data => {
  data.toLowerCase = () => (text, render) => render(text).toLowerCase();
  data.capitalize = () => (text, render) => render(text).replace(/\b\w/g, l => l.toUpperCase());
  data.hyphenate = () => (text, render) => render(text).replace(' ', '-');

  return data;
};

/**
 * Writes `protocol.md` using `protocol.mustache`.
 *
 * @param  {Object} data Data to assign to the mustache template.
 */
const generateProtocol = (templatePath, data) => {
  data = bindMustacheHelpers(data);

  const template = fs.readFileSync(templatePath).toString();
  let generated = mustache.render(template, data);
  generated = toc.insert(generated);

  return generated;
};

const files = glob.sync("./*.@(cpp|h)");
const comments = processComments(parseFiles(files));
const markdown = generateProtocol('docs/protocol.mustache', comments);

fs.writeFileSync('docs/comments.json', JSON.stringify(comments, null, 2));
fs.writeFileSync('docs/protocol.md', markdown);
