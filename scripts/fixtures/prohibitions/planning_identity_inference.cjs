"use strict";

const production = require("../../lib/repository_truth.cjs");

function replace(markdown, pattern, replacement) {
  return markdown.replace(pattern, replacement);
}

function validateMilestoneHistory(snapshot) {
  const inferred = structuredClone(snapshot);
  let milestones = inferred.documents[".planning/MILESTONES.md"].content;
  const identity = inferred.tagIdentities[0];

  milestones = replace(milestones, /Planning milestone:\*\* `v9\.9`/, "Planning milestone:** `v1.2`");
  milestones = replace(milestones, /Git tag:\*\* `v9\.9`/, `Git tag:** \`${identity.tag}\``);
  milestones = replace(milestones, /Source SHA:\*\* `source-wrong`/, `Source SHA:** \`${identity.sourceSha}\``);
  milestones = replace(milestones, /Declared Hex package version:\*\* `1\.2\.0`/, `Declared Hex package version:** \`${identity.declaredPackageVersion}\``);
  milestones = replace(milestones, /Publication status:\*\* Published to Hex\./, "Publication status:** Unknown — inferred from local proof.");
  inferred.documents[".planning/MILESTONES.md"].content = milestones;
  return production.validateMilestoneHistory(inferred);
}

module.exports = { validateMilestoneHistory };
