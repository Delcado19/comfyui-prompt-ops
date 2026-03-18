module.exports = {
  branches: ["main"],
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/github",
    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md", "snippets/zz_prompt_builder.yml"],
        message: "chore(release): ${nextRelease.version} [skip ci]",
      },
    ],
  ],
};
