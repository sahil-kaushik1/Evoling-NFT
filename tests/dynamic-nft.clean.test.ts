import { describe, it, expect } from "vitest";

// Clarinet vitest globals are injected by the environment
declare const simnet: any;
declare const types: any;

const CONTRACT_NAME_NFT = "dynamic-nft";

describe("Clean test: Mint NFT", () => {
  it("mints and starts at stage 1", () => {
    const user = simnet.wallet_1 ?? simnet.deployer;

    const contractId = `${simnet.deployer}.${CONTRACT_NAME_NFT}`;

    // Mint
    const receipt = simnet.callPublicFn(contractId, "buy-nft", [], user.address);
    receipt.result.expectOk().expectUint(1);

    // Check metadata for token 1
    const meta = simnet.callReadOnlyFn(contractId, "get-token-uri", [types.uint(1)], user.address);
    const val = meta.result.expectOk().expectAscii();
    expect(val.startsWith("data:image/svg+xml;utf8,")).toBe(true);
  });
});
