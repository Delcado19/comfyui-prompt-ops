import { app } from "../../scripts/app.js";

// Client-side UI for the PromptOpsBrowser node: fetches the snippet
// library once per node instance, offers polarity + category filters over
// it, and an "Einfügen" button that appends the selected entry's text into
// the node's own positive_text/negative_text widgets. See nodes.py for why
// this lives in JS instead of INPUT_TYPES (dependent dropdowns + a button
// aren't expressible there).
app.registerExtension({
    name: "PromptOps.Browser",
    async beforeRegisterNodeDef(nodeType, nodeData) {
        if (nodeData.name !== "PromptOpsBrowser") return;

        const onNodeCreated = nodeType.prototype.onNodeCreated;
        nodeType.prototype.onNodeCreated = function () {
            onNodeCreated?.apply(this, arguments);
            const node = this;

            let categories = [];
            const positiveWidget = node.widgets.find((w) => w.name === "positive_text");
            const negativeWidget = node.widgets.find((w) => w.name === "negative_text");

            const polarityWidget = node.addWidget(
                "combo",
                "polarity",
                "Positive",
                () => rebuildEntries(),
                { values: ["Positive", "Negative"] }
            );
            const categoryWidget = node.addWidget(
                "combo",
                "category",
                "Alle",
                () => rebuildEntries(),
                { values: ["Alle"] }
            );
            const entryWidget = node.addWidget("combo", "entry", "", () => {}, { values: [""] });
            const modeWidget = node.addWidget(
                "combo",
                "mode",
                "Getrennt",
                () => {},
                { values: ["Getrennt", "Nur ein Prompt"] }
            );

            function rebuildEntries() {
                const wantPolarity = polarityWidget.value === "Positive" ? "positive" : "negative";
                const wantCategory = categoryWidget.value;
                const options = [];
                const lookup = {};

                for (const category of categories) {
                    if (category.polarity !== wantPolarity) continue;
                    if (wantCategory !== "Alle" && category.label !== wantCategory) continue;
                    for (const entry of category.entries) {
                        const label = `[${category.label}] ${entry.trigger} — ${entry.text}`;
                        options.push(label);
                        lookup[label] = { text: entry.text, polarity: category.polarity };
                    }
                }

                entryWidget.options.values = options.length ? options : ["(keine Einträge)"];
                entryWidget.value = entryWidget.options.values[0];
                entryWidget._lookup = lookup;
            }

            node.addWidget("button", "Einfügen", null, () => {
                const chosen = entryWidget._lookup?.[entryWidget.value];
                if (!chosen) return;

                const forcePositive = modeWidget.value === "Nur ein Prompt";
                const target =
                    chosen.polarity === "negative" && !forcePositive ? negativeWidget : positiveWidget;

                target.value = target.value ? `${target.value}, ${chosen.text}` : chosen.text;
            });

            fetch("/prompt_ops/library")
                .then((response) => response.json())
                .then((data) => {
                    if (data.error) {
                        categories = [];
                        rebuildEntries();
                        return;
                    }
                    categories = data;
                    categoryWidget.options.values = ["Alle", ...new Set(categories.map((c) => c.label))];
                    rebuildEntries();
                })
                .catch(() => {
                    categories = [];
                    rebuildEntries();
                });
        };
    },
});
