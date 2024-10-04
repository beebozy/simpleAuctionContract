import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const biddingTime=5;

const LockModule = buildModule("LockModule", (m) => {
  

  const lock = m.contract("SimpleAuction",[biddingTime]);

  return { lock };
});

export default LockModule;
