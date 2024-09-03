import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const AirdropModule = buildModule("Airdrops", (m) => {
  const tokenAddress = "0xeeaaf3d79f1cec8b061184487f7c921e1fcae425";

  const merkleRoot =
    "0x1c00164ae916880de11616af08488674f3f1177d7c27ecf2e09039be9bc10158";

  const Airdrop = m.contract("Airdrop", [tokenAddress, merkleRoot]);

  return { Airdrop };
});

export default AirdropModule;
