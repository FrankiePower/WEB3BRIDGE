import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SuperTokenModule = buildModule("SuperTokenModule", (m) => {
  const SuperToken = m.contract("SuperToken");

  return { SuperToken };
});

export default SuperTokenModule;
