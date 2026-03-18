module.exports = {
  branches: ["main"],
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",

    // 👉 SCHREIBT CHANGELOG.md
    "@semantic-release/changelog",

    // 👉 COMMITTET DIE ÄNDERUNG INS REPO
    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md"],
        message: "chore(release): ${nextRelease.version} [skip ci]",
      },
    ],

    // 👉 ERSTELLT GITHUB RELEASE
    "@semantic-release/github",
  ],
};
