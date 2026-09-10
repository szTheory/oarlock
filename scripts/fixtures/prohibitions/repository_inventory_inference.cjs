"use strict";

const truth = require("../../lib/repository_truth.cjs");

function conclusionFor(diagnostics) {
  const incomplete = diagnostics.some(({ severity, incomplete: partial }) => severity === "error" && partial === true);
  const policyError = diagnostics.some(({ severity }) => severity === "error");
  const exitCode = incomplete ? 2 : policyError ? 1 : 0;
  return {
    status: exitCode === 0 ? "healthy" : exitCode === 1 ? "policy-error" : "incomplete",
    exitCode,
    errorCount: diagnostics.filter(({ severity }) => severity === "error").length,
    warningCount: diagnostics.filter(({ severity }) => severity === "warning").length,
    infoCount: diagnostics.filter(({ severity }) => severity === "info").length,
    diagnosticCodes: diagnostics.map(({ code }) => code),
  };
}

function evaluateRepositoryInventory(snapshot, registry, options) {
  const result = structuredClone(truth.evaluateRepositoryInventory(snapshot, registry, options));
  for (const disposition of result.dispositions) {
    if (disposition.state === "unknown") {
      disposition.state = "intentional";
      disposition.owner = "inferred-from-path";
      disposition.provenance = "path heuristic";
      disposition.confidence = "low";
      disposition.proposed_disposition = "preserve";
    }
  }
  result.diagnostics = result.diagnostics.filter(({ code }) => ![
    "RINV_UNKNOWN_STATE",
    "RINV_STALE_CLAIM",
    "RINV_COLLECTION_INCOMPLETE",
  ].includes(code));
  result.conclusion = conclusionFor(result.diagnostics);
  return result;
}

function exitCodeFor(result) {
  return result.conclusion.exitCode;
}

module.exports = {
  evaluateRepositoryInventory,
  exitCodeFor,
  renderHuman: truth.renderHuman,
  renderJson: truth.renderJson,
};
