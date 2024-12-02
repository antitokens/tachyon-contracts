// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library PowerFormulaConstants {
    uint8 constant MIN_PRECISION = 32;
    uint8 constant MAX_PRECISION = 127;

    bytes public constant MAX_EXP_ARRAY = abi.encodePacked(
        [
            0xd7,
            0x19f,
            0x31b,
            0x5f6,
            0xb6e,
            0x15ec,
            0x2a0c,
            0x50a2,
            0x9aa2,
            0x1288c,
            0x238b2,
            0x4429a,
            0x82b78,
            0xfaadc,
            0x1e0bb8,
            0x399e96,
            0x6e7f88,
            0xd3e7a3,
            0x1965fea,
            0x30b5057,
            0x5d681f3,
            0xb320d03,
            0x15784a40,
            0x292c5bdd,
            0x4ef57b9b,
            0x976bd995,
            0x122624e32,
            0x22ce03cd5,
            0x42beef808,
            0x7ffffffff,
            0xf577eded5,
            0x1d6bd8b2eb,
            0x386bfdba29,
            0x6c3390ecc8,
            0xcf8014760f,
            0x18ded91f0e7,
            0x2fb1d8fe082,
            0x5b771955b36,
            0xaf67a93bb50,
            0x15060c256cb2,
            0x285145f31ae5,
            0x4d5156639708,
            0x944620b0e70e,
            0x11c592761c666,
            0x2214d10d014ea,
            0x415bc6d6fb7dd,
            0x7d56e76777fc5,
            0xf05dc6b27edad,
            0x1ccf4b44bb4820,
            0x373fc456c53bb7,
            0x69f3d1c921891c,
            0xcb2ff529eb71e4,
            0x185a82b87b72e95,
            0x2eb40f9f620fda6,
            0x5990681d961a1ea,
            0xabc25204e02828d,
            0x14962dee9dc97640,
            0x277abdcdab07d5a7,
            0x4bb5ecca963d54ab,
            0x9131271922eaa606,
            0x116701e6ab0cd188d,
            0x215f77c045fbe8856,
            0x3ffffffffffffffff,
            0x7abbf6f6abb9d087f,
            0xeb5ec597592befbf4,
            0x1c35fedd14b861eb04,
            0x3619c87664579bc94a,
            0x67c00a3b07ffc01fd6,
            0xc6f6c8f8739773a7a4,
            0x17d8ec7f04136f4e561,
            0x2dbb8caad9b7097b91a,
            0x57b3d49dda84556d6f6,
            0xa830612b6591d9d9e61,
            0x1428a2f98d728ae223dd,
            0x26a8ab31cb8464ed99e1,
            0x4a23105873875bd52dfd,
            0x8e2c93b0e33355320ead,
            0x110a688680a7530515f3e,
            0x20ade36b7dbeeb8d79659,
            0x3eab73b3bbfe282243ce1,
            0x782ee3593f6d69831c453,
            0xe67a5a25da41063de1495,
            0x1b9fe22b629ddbbcdf8754,
            0x34f9e8e490c48e67e6ab8b,
            0x6597fa94f5b8f20ac16666,
            0xc2d415c3db974ab32a5184,
            0x175a07cfb107ed35ab61430,
            0x2cc8340ecb0d0f520a6af58,
            0x55e129027014146b9e37405,
            0xa4b16f74ee4bb2040a1ec6c,
            0x13bd5ee6d583ead3bd636b5c,
            0x25daf6654b1eaa55fd64df5e,
            0x4898938c9175530325b9d116,
            0x8b380f3558668c46c91c49a2,
            0x10afbbe022fdf442b2a522507,
            0x1ffffffffffffffffffffffff,
            0x3d5dfb7b55dce843f89a7dbcb,
            0x75af62cbac95f7dfa3295ec26,
            0xe1aff6e8a5c30f58221fbf899,
            0x1b0ce43b322bcde4a56e8ada5a,
            0x33e0051d83ffe00feb432b473b,
            0x637b647c39cbb9d3d26c56e949,
            0xbec763f8209b7a72b0afea0d31,
            0x16ddc6556cdb84bdc8d12d22e6f,
            0x2bd9ea4eed422ab6b7b072b029e,
            0x54183095b2c8ececf30dd533d03,
            0xa14517cc6b9457111eed5b8adf1,
            0x13545598e5c23276ccf0ede68034,
            0x2511882c39c3adea96fec2102329,
            0x471649d87199aa990756806903c5,
            0x88534434053a9828af9f37367ee6,
            0x1056f1b5bedf75c6bcb2ce8aed428,
            0x1f55b9d9ddff141121e70ebe0104e,
            0x3c1771ac9fb6b4c18e229803dae82,
            0x733d2d12ed20831ef0a4aead8c66d,
            0xdcff115b14eedde6fc3aa5353f2e4,
            0x1a7cf47248624733f355c5c1f0d1f1,
            0x32cbfd4a7adc790560b3335687b89b,
            0x616a0ae1edcba5599528c20605b3f6,
            0xbad03e7d883f69ad5b0a186184e06b,
            0x16641a07658687a905357ac0ebe198b,
            0x2af09481380a0a35cf1ba02f36c6a56,
            0x5258b7ba7725d902050f6360afddf96,
            0x9deaf736ac1f569deb1b5ae3f36c130,
            0x12ed7b32a58f552afeb26faf21deca06,
            0x244c49c648baa98192dce88b42f53caf,
            0x459c079aac334623648e24d17c74b3dc,
            0x857ddf0117efa215952912839f6473e6
        ]
    );

    bytes public constant MAX_VAL_ARRAY = abi.encodePacked(
        [
            0x2550a7d99147ce113d27f304d24a422c3d,
            0x1745f7d567fdd8c93da354496cf4dddf34,
            0xb5301cf4bf20167721bcdbe218a66f1e0,
            0x5e2d2ca56fae9ef2e524ba4d0f75b8754,
            0x2f45acad795bce6dcd748391bb828dcea,
            0x17f631b6609d1047920e1a1f9613f870d,
            0xc29d4a7745ae89ef20a05db656441649,
            0x6242dea9277cf2d473468985313625bb,
            0x31aef9b37fbc57d1ca51c53eb472c345,
            0x1923b23c38638957faeb8b4fe57b5ead,
            0xcb919ec79bf364210433b9b9680eadd,
            0x67186c63186761709a96a91d44ff2bf,
            0x343e6242f854acd626b78022c4a8002,
            0x1a7efb7b1b687ccb2bb413b92d5e413,
            0xd72d0627fadb6aa6e0f3c994a5592a,
            0x6d4f32a7dcd0924c122312b7522049,
            0x37947990f145344d736c1e7e5cff2f,
            0x1c49d8ceb31e3ef3e98703e0e656cc,
            0xe69cb6255a180e2ead170f676fa3c,
            0x75a24620898b4a19aafdfa67d23e8,
            0x3c1419351dd33d49e1ce203728e25,
            0x1eb97e709f819575e656eefb8bd98,
            0xfbc4a1f867f03d4c057d522b6523,
            0x812507c14867d2237468ba955def,
            0x425b9d8ca5a58142d5172c3eb2b5,
            0x2228e76a368b75ea80882c9f6010,
            0x119ed9f43c52cdd38348ee8d7b23,
            0x91bfcff5e91c7f115393af54bad,
            0x4b8845f19f7b4a93653588ce846,
            0x273fa600431f30b0f21b619c797,
            0x1474840ba4069691110ff1bb823,
            0xab212322b671a11d3647e3ecaf,
            0x59ce8876bf3a3b1b396ae19c95,
            0x2f523e50d3b0d68a3e39f2f06e,
            0x190c4f51698c5ee5c3b34928a0,
            0xd537c5d5647f2a79965d56f94,
            0x72169649d403b5b512b40d5c2,
            0x3d713a141a21a93a218c980c1,
            0x215544c77538e6de9275431a6,
            0x123c0edc8bf784d147024b7df,
            0xa11eada236d9ccb5d9a46757,
            0x59f185464ae514ade263ef14,
            0x32d507935c586248656e95cb,
            0x1d2270a4f18efd8eab5a27d7,
            0x10f7bfaf758e3c1010bead08,
            0xa101f6bc5df6cc4cf4cb56d,
            0x61773c45cb6403833991e6e,
            0x3c5f563f3abca8034b91c7d,
            0x265cd2a70d374397f75a844,
            0x1911bbf62c34780ee22ce8e,
            0x10e3053085e97a7710c2e6d,
            0xbbfc0e61443560740fa601,
            0x874f16aa407949aebced14,
            0x64df208d66f55c59261f5d,
            0x4dee90487e19a58fbf52e9,
            0x3e679f9e3b2f65e9d9b0db,
            0x33c719b34c57f9f7a922f6,
            0x2c7c090c36927c216fe17c,
            0x2789fc1ccdbd02af70650f,
            0x2451aae7a1741e150c6ae0,
            0x22700f74722225e8c308e6,
            0x21aae2600cf1170129eb92,
            0x21e552192ec12eccaa1d44,
            0x231a0b6c2a250a15897b8a,
            0x255901ff2640b9b00fef5e,
            0x28c842993fe2877ca68b09,
            0x2da7b7138200abf065bc12,
            0x34584e19c1677771772dbf,
            0x3d678fd12af3f51aa5828a,
            0x49a16c994ca36bb50c32c9,
            0x5a2b2d67887520aacedab6,
            0x70ac191abaee2a72987db6,
            0x8f8afbb1a74e96379df7b1,
            0xba4bd6d86b43467101fd6c,
            0xf61f8e0679ef553e95c271,
            0x14ac1e3b06c9771ad8f351c,
            0x1c3d320c47b0e10030f080e,
            0x272f678a02b5bd5dcc145a7,
            0x3732bb25f4914992758a3aa,
            0x4ee25a85a30b4e758af15a0,
            0x724dbc7344a886ed20dbae2,
            0xa7d64de739a14a222daf692,
            0xf99876906cf6526b6b82ecc,
            0x177bbaca105a36b48757a319,
            0x23c442370233418f33964a65,
            0x3716c05776b217ecbb587d11,
            0x55c42bb597ed985a9d69778e,
            0x86e8f9efa6efeba9e16b0a90,
            0xd651f2e547d194ee8b6d9a69,
            0x157b681e454d31a35819b1989,
            0x22c414309a2b397b4f8e0eb28,
            0x38c1a2330fcf634a5db1378a0,
            0x5d6efaaf8133556840468bbbb,
            0x9b0c82dee2e1f20d0a157a7ae,
            0x10347bdd997b95a7905d850436,
            0x1b4c902e273a586783055cede8,
            0x2e50642e85a0b7c589bac2651b,
            0x4f1b7f75028232ad3258b8b742,
            0x880028111c381b5279db2271c3,
            0xeb454460fe475acef6b927865e,
            0x1996fab0c95ac4a2b5cfa8f555d,
            0x2cc9f3994685c8d3224acb9fea1,
            0x4ed2e079d693966878c7149351a,
            0x8b740d663b523dad8b67451d8fc,
            0xf7f73c5d826e196ff66a259204c,
            0x1bb0d7eb2857065dcad087986fa6,
            0x31b4dfa1eedd2bd17d3504820344,
            0x599fae8ac47c48cf034887f489bb,
            0xa249948898a0e444bffa21361f42,
            0x12711786051c98ca2acc4adf7ba6a,
            0x21a98821bf01e72cc3f724b65a121,
            0x3dad0dd7c71f7b443dddd56fede23,
            0x716933ca69ac1b439f976665fafdf,
            0xd143a4beebca9707458aad7b22dcd,
            0x18369cb4cd8522c1b28abc22a3e805,
            0x2cf816f46d1971ec18f0ffb6922e86,
            0x53c58e5a59ee4d9fd7f747f67a3aac,
            0x9c833e3c0364561037250933eab9a9,
            0x1253c9d983f03e6a0955355049411cb,
            0x226e05852615979ea99f6ef68dbab51,
            0x40d8c81134ee9e16db1e0108defbb9f,
            0x7a70173a27075f4b9482d36deadc951,
            0xe7b966d76665f99c3fb1791404f62c6,
            0x1b78e22c38ae6aa69d36b8ccfade23fd,
            0x3439aeef615a970c9678397b6ad71179,
            0x637d37d6cb204d7419ac094d7e89f0dd,
            0xbde80a98943810876a7852209de22be2,
            0x16b3160a3c604c6667ff40ff1882b0fcf
        ]
    );
}
