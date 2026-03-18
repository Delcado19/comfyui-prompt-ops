module.exports = {
  branches: ["main"],
  plugins: [
    // analysiert commits (fix:, feat:, etc.)
    "@semantic-release/commit-analyzer",

    // erzeugt release notes
    "@semantic-release/release-notes-generator",

    // 🔥 schreibt CHANGELOG.md
    "@semantic-release/changelog",

    // 🔥 committed CHANGELOG.md zurück ins repo
    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md"],
        message: "chore(release): ${nextRelease.version} [skip ci]",
      },
    ],

    // erstellt GitHub Release
    "@semantic-release/github",
  ],
};
