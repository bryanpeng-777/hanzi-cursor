import { DOCS_BASE_URL } from ".";

export default async function queryDocs(framework: string, components: string[]) {
  const urls = components.map((comp) => `${DOCS_BASE_URL}/tdesign-${framework}/${comp}/api.md`);

  const docs = await Promise.all(
    urls.map(async (url) => {
      const res = await fetch(url);
      if (!res.ok) {
        throw new Error(`Failed to fetch ${url}`);
      }
      return await res.text();
    })
  );

  return docs;
}

const args = process.argv.slice(2);
const framework = args[0];
const components = args[1] ? args[1].split(",") : [];

if (!framework || components.length === 0) {
  console.error("Usage: tsx query_docs.ts <framework> <component1,component2>");
  process.exit(1);
}

queryDocs(framework, components)
  .then((docs) => {
    docs.forEach((doc) => {
      console.log(`${doc}\n`);
    });
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
