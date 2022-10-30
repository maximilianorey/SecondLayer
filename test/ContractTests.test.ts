import "@openzeppelin/hardhat-upgrades";

import { modPow } from "bigint-mod-arith";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { ethers } from "hardhat";

chai.use(solidity);

describe("SecondLayer", function () {
  it("SOMETHING", async () => {
    const wallets = await ethers.getSigners();

    const n = BigInt("856911196688842909152845259498660691866048457");
    const m = BigInt("878944667195838994447084255955267549107925907");
    const p = BigInt(
      "57865308379927293945012186408951094763827862981364399883321545244649849672021"
    );

    const secondLayerFactory = await ethers.getContractFactory("NFTsManager");
    const secondLayer = await secondLayerFactory.deploy(
      "856911196688842909152845259498660691866048457",
      "878944667195838994447084255955267549107925907",
      "57865308379927293945012186408951094763827862981364399883321545244649849672021"
    );

    const g = (await secondLayer.getGenerator(wallets[0].address)).toBigInt();
    const a = BigInt(Math.floor(Math.random() * Number.MAX_SAFE_INTEGER));

    const fReg = modPow(g, n * a, p);
    const sReg = modPow(g, p - BigInt(1) - m * (a - BigInt(1)), p);

    const c = modPow(g, p - BigInt(1) - m, p);

    expect(
      ((modPow(fReg, m, p) * modPow(sReg * c, n, p)) % p).toString()
    ).to.be.equal("1");
  });

  it.only("Test Deposit", async () => {
    const [w] = await ethers.getSigners();
    const n = BigInt("856911196688842909152845259498660691866048457");
    const m = BigInt("878944667195838994447084255955267549107925907");
    const p = BigInt(
      "57865308379927293945012186408951094763827862981364399883321545244649849672021"
    );

    const secondLayerFactory = await ethers.getContractFactory("NFTsManager");
    const erc721Factory = await ethers.getContractFactory("TestERC721");
    const erc721 = await erc721Factory.deploy("TEST", "TE");
    const secondLayer = await secondLayerFactory.deploy(
      "856911196688842909152845259498660691866048457",
      "878944667195838994447084255955267549107925907",
      "57865308379927293945012186408951094763827862981364399883321545244649849672021"
    );

    const a = BigInt(5);

    const g = (await secondLayer.getGenerator(w.address)).toBigInt();

    const fReg = modPow(g, n * a, p);
    const sReg = modPow(g, p - BigInt(2) - m * a, p);

    await (await erc721.mint(w.address, "0")).wait();

    await (
      await secondLayer.deposit(
        erc721.address,
        "0",
        fReg.toString(),
        sReg.toString(),
        g.toString()
      )
    ).wait();
  });

  it("Test", async function () {
    const wallets = await ethers.getSigners();

    const iterations = 10;

    const tokens: Array<bigint> = new Array(iterations);
    const generators: Array<bigint> = new Array(iterations);

    const n = BigInt("856911196688842909152845259498660691866048457");
    const m = BigInt("878944667195838994447084255955267549107925907");
    const p = BigInt(
      "57865308379927293945012186408951094763827862981364399883321545244649849672021"
    );

    const secondLayerFactory = await ethers.getContractFactory("NFTsManager");
    const erc721Factory = await ethers.getContractFactory("TestERC721");
    const erc721 = await erc721Factory.deploy("TEST", "TE");
    const secondLayer = await secondLayerFactory.deploy(
      "856911196688842909152845259498660691866048457",
      "878944667195838994447084255955267549107925907",
      "57865308379927293945012186408951094763827862981364399883321545244649849672021"
    );

    for (let i = 0; i < iterations; i += 1) {
      const w = wallets[Math.floor(Math.random() * wallets.length)];
      const g = (await secondLayer.getGenerator(w.address)).toBigInt();
      generators[i] = g;
      await (await erc721.mint(w.address, i.toString())).wait();
      const a = BigInt(Math.floor(Math.random() * Number.MAX_SAFE_INTEGER));
      tokens[i] = a;
      const fReg = modPow(g, n * a, p);
      const sReg = modPow(g, p - BigInt(2) - m * a, p);

      const op1 = (modPow(g, p - BigInt(2) - m * a, p) * g) % p;
      const op2 = modPow(g, p - BigInt(1) - m * a, p);

      expect(op1.toString()).to.be.equal(op2.toString());

      const c = g;

      expect(
        ((modPow(fReg, m, p) * modPow(sReg * c, n, p)) % p).toString()
      ).to.be.equal("1");

      await (
        await secondLayer
          .connect(w)
          .deposit(
            erc721.address,
            i.toString(),
            fReg.toString(),
            sReg.toString(),
            g.toString()
          )
      ).wait();
      await (
        await erc721
          .connect(w)
          .transferFrom(w.address, secondLayer.address, i.toString())
      ).wait();
    }

    for (let i = 0; i < iterations; i += 1) {
      let fRegister = BigInt("1");
      let sRegister = BigInt("1");
      for (let j = 0; j < 100; j += 1) {
        const generator = generators[j];
        const oldA = tokens[j];
        const newA = BigInt(
          Math.floor(Math.random() * Number.MAX_SAFE_INTEGER)
        );
        tokens[j] = newA;
        fRegister = fRegister * modPow(generator, p - BigInt(1) - n * oldA, p);
        sRegister = sRegister * modPow(generator, m * newA, p);
        fRegister = fRegister * modPow(generator, n * newA, p);
        sRegister = sRegister * modPow(generator, p - BigInt(1) - m * newA, p);
      }
      console.log(`BLOCK: ${i}`);
      await (await secondLayer.saveBlock(fRegister, sRegister)).wait();
    }
  });
});
