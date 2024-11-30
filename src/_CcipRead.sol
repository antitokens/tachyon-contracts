// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";

/**
 * @title Off-Chain ENS Records Manager
 * @author freetib.eth, sshmatrix.eth [https://github.com/namesys-eth]
 * Github : https://github.com/namesys-eth/ccip2-eth-resolver
 * Client : https://namesys.eth.limo
 */
contract CcipRead is iCcipRead {
    /// @dev - Revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev - Receive donation
    receive() external payable {
        emit ThankYou(msg.sender, msg.value);
    }

    /// Events
    event ThankYou(address indexed addr, uint256 indexed value);
    event GatewayUpdated(address indexed oldAddr, address indexed newAddr);
    event UpdatedWrapper(address indexed newAddr, bool indexed status);
    event ApprovedSigner(
        address owner,
        bytes32 indexed node,
        address indexed delegate,
        bool indexed approved
    );
    event InterfaceUpdated(bytes4 indexed sig, bool indexed status);

    /// Errors
    error InvalidSignature(string _message);
    error InvalidRequest(string _message);
    error BadConfig(string _message);
    error NotAuthorised(string _message);
    error PlsFundDevs();

    /// @dev - CCIP-Read Gateways
    iGatewayManager public gateway;
    /// @dev - Deployed Chain ID
    string chainID;

    /// Mappings
    /// @dev - On-chain singular Manager database
    /// Note - Manager (= isApprovedSigner) is someone who can manage off-chain records for a domain on behalf of its owner
    mapping(address => mapping(bytes32 => mapping(address => bool)))
        public isApprovedSigner;
    /// @dev - List of all wrapping contracts to be declared in contructor
    mapping(address => bool) public isWrapper;

    /// Interfaces
    mapping(bytes4 => bool) public supportsInterface;

    /// @dev - Constructor
    constructor(address _gateway) {
        gateway = iGatewayManager(_gateway);
        chainID = block.chainid == 1 ? "1" : "5"; // Set ChainID
        /// @dev - Sets <> as Wrapper
        isWrapper[0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401] = true;
        emit UpdatedWrapper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401, true);
        isWrapper[0x114D4603199df73e7D157787f8778E21fCd13066] = true;
        emit UpdatedWrapper(0x114D4603199df73e7D157787f8778E21fCd13066, true);

        /// @dev - Set necessary interfaces
        supportsInterface[iERC165.supportsInterface.selector] = true;
        supportsInterface[iERC3668.resolve.selector] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[iCcipRead.setRecordhash.selector] = true;
        supportsInterface[iCcipRead.setOwnerhash.selector] = true;
        supportsInterface[iCallbackType.signedRecord.selector] = true;
        supportsInterface[iCallbackType.signedRedirect.selector] = true;
    }

    /**
     * @dev EIP-2544/EIP-3668 core resolve() function; aka CCIP-Read
     * @param name - Domain to resolve; must be DNS encoded
     * @param request - Encoding-specific function to resolve
     * @return result - Triggers Off-chain Lookup
     * Note - Return value is not used
     */
    function resolve(
        bytes calldata name,
        bytes calldata request
    ) external view returns (bytes memory) {
        unchecked {
            revert OffchainLookup(
                address(this),
                gateway.randomGateways(
                    _recordhash,
                    string.concat("/.well-known/", _path, "/", _recType),
                    uint256(_checkhash)
                ), // Generate pseudo-random list of gateways
                abi.encodePacked(uint16(block.timestamp / 60)), // Cache = 60 seconds
                iCcipRead.__callback.selector, // Callback function
                abi.encode(
                    _node,
                    block.number - 1,
                    _checkhash,
                    _domain,
                    _recType,
                    _path,
                    name,
                    request
                )
            );
        }
    }

    /**
     * @dev Default Callback function
     * @param response - Response of CCIP-Read call
     * @param extradata - Extra data used by callback
     * @return result - Concludes Off-chain Lookup
     * Note - Return value is not used
     */
    function __callback(
        bytes calldata response,
        bytes calldata extradata
    ) external view returns (bytes memory result) {
        /// Get signer-type from response identifier
        bytes4 _type = bytes4(response[:4]);
        if (!supportsInterface[_type]) {
            /// @dev Future features in __fallback
            return gateway.__fallback(response, extradata);
        }
        (
            bytes32 _node, // 
            uint256 _blocknumber, // Blocknumber for timeout checks
            bytes32 _checkhash, // Extra checkhash
            string memory _domain, // 
            string memory _recType, // 
            ,
            ,
            bytes memory _request //
        ) = abi.decode(
                extradata,
                (
                    bytes32,
                    uint256,
                    bytes32,
                    string,
                    string,
                    string,
                    bytes,
                    bytes
                )
            );
        /// @dev - Timeout in 6 blocks
        if (block.number > _blocknumber + 7) {
            revert InvalidRequest("BLOCK_TIMEOUT");
        }
        /// @dev - Verify checkhash
        if (
            _checkhash !=
            keccak256(
                abi.encodePacked(
                    this,
                    blockhash(_blocknumber),
                    _owner,
                    _domain,
                    _recType,
                    _request
                )
            )
        ) {
            revert InvalidRequest("BAD_CHECKSUM");
        }
        // Signer could be:
        // a) Owner
        // OR, b) On-chain approved manager
        // OR, c) Off-chain approved signer
        address _signer;
        /// Signature associated with the record
        bytes memory _recordSignature;
        /// Init off-chain manager's signature request
        string memory signRequest;
        /// Off-chain signature approving record signer (if signer != owner or on-chain manager)
        bytes memory _approvedSig;
        /// @dev CCIP-Read response decode
        (_signer, _recordSignature, _approvedSig, result) = abi.decode(
            response[4:],
            (address, bytes, bytes, bytes)
        );
    }

    /**
     * @dev Redirects the CCIP-Read request to another ENS Domain
     * @param _encoded - ENS domain to resolve; must be DNS encoded
     * @param _requested - Originally requested encoding-specific function to resolve
     * @return _selector - Redirected function selector
     * @return _namehash - Redirected namehash
     * @return _redirectRequest - Redirected request
     * @return domain - String-formatted ENS domain
     */
    function redirectService(
        bytes calldata _encoded,
        bytes calldata _requested
    )
        external
        view
        returns (
            bytes4 _selector,
            bytes32 _namehash,
            bytes memory _redirectRequest,
            string memory domain
        )
    {
        uint256 index = 1;
        uint256 n = 1;
        uint256 len = uint8(bytes1(_encoded[0]));
        bytes[] memory _labels = new bytes[](42);
        _labels[0] = _encoded[1:n += len];
        domain = string(_labels[0]);
        while (_encoded[n] > 0x0) {
            len = uint8(bytes1(_encoded[n:++n]));
            _labels[index] = _encoded[n:n += len];
            domain = string.concat(domain, ".", string(_labels[index]));
        }
        bytes32 _owned;
        _namehash = keccak256(
            abi.encodePacked(bytes32(0), keccak256(_labels[--index]))
        );
        while (index > 0) {
            _namehash = keccak256(
                abi.encodePacked(_namehash, keccak256(_labels[--index]))
            );
            if (ENS.recordExists(_namehash)) {
                _owned = _namehash;
            }
        }
        if (_owned == bytes32(0)) {
            revert InvalidRequest("NOT_REGISTERED");
        }
        _selector = bytes4(_requested[:4]);
        _redirectRequest = abi.encodePacked(
            _selector,
            _namehash,
            _requested.length > 36 ? _requested[36:] : bytes("")
        );
        _namehash = _owned;
    }

    /**
     * @dev Checks for manager access to an ENS domain for record management
     * @param _owner - Owner of ENS domain
     * @param _approvedSigner - Manager address to check
     * @param _node - Namehash of ENS domain
     * @param _signature - Signature to verify
     * @param _domain - String-formatted ENS domain
     * @return  - Whether manager is approved by the owner
     */
    function approvedSigner(
        address _owner,
        address _approvedSigner,
        bytes32 _node,
        bytes memory _signature,
        string memory _domain
    ) public view returns (bool) {
        address _signer = iCcipRead(this).getSigner(
            string.concat(
                "Requesting Signature To Approve ENS Records Signer\n",
                "\nOrigin: ",
                _domain,
                "\nApproved Signer: eip155:",
                chainID,
                ":",
                gateway.toChecksumAddress(_approvedSigner),
                "\nApproved By: eip155:",
                chainID,
                ":",
                gateway.toChecksumAddress(_owner)
            ),
            _signature
        );
        return (_signer == _owner || isApprovedSigner[_owner][_node][_signer]);
    }

    /**
     * @dev Checks if a signature is valid
     * @param _message - String-formatted message that was signed
     * @param _signature - Compact signature to verify
     * @return _signer - Signer of message
     * @notice - Signature Format:
     * a) 64 bytes - bytes32(r) + bytes32(vs) ~ compact, or
     * b) 65 bytes - bytes32(r) + bytes32(s) + uint8(v) ~ packed, or
     * c) 96 bytes - bytes32(r) + bytes32(s) + uint256(v) ~ longest
     */
    function getSigner(
        string calldata _message,
        bytes calldata _signature
    ) external view returns (address _signer) {
        bytes32 r = bytes32(_signature[:32]);
        bytes32 s;
        uint8 v;
        uint256 len = _signature.length;
        if (len == 64) {
            bytes32 vs = bytes32(_signature[32:]);
            s =
                vs &
                bytes32(
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
            v = uint8((uint256(vs) >> 255) + 27);
        } else if (len == 65) {
            s = bytes32(_signature[32:64]);
            v = uint8(bytes1(_signature[64:]));
        } else if (len == 96) {
            s = bytes32(_signature[32:64]);
            v = uint8(uint256(bytes32(_signature[64:])));
        } else {
            revert InvalidSignature("BAD_SIG_LENGTH");
        }
        if (
            s >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert InvalidSignature("INVALID_S_VALUE");
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                gateway.uintToString(bytes(_message).length),
                _message
            )
        );
        _signer = ecrecover(digest, v, r, s);
        if (_signer == address(0)) {
            revert InvalidSignature("ZERO_ADDR");
        }
    }

    /**
     * @dev Sets a signer (= manager) as approved to manage records for a node
     * @param _node - Namehash of ENS domain
     * @param _signer - Address of signer (= manager)
     * @param _approval - Status to set
     */
    function approve(bytes32 _node, address _signer, bool _approval) external {
        isApprovedSigner[msg.sender][_node][_signer] = _approval;
        emit ApprovedSigner(msg.sender, _node, _signer, _approval);
    }

    /**
     * @dev Sets multiple signers (= managers) as approved to manage records for a node
     * @param _node - Namehash[] of ENS domains
     * @param _signer - Address[] of signers (= managers)
     * @param _approval - Status[] to set
     */
    function multiApprove(
        bytes32[] calldata _node,
        address[] calldata _signer,
        bool[] calldata _approval
    ) external {
        uint256 len = _node.length;
        for (uint256 i = 0; i < len; i++) {
            isApprovedSigner[msg.sender][_node[i]][_signer[i]] = _approval[i];
            emit ApprovedSigner(msg.sender, _node[i], _signer[i], _approval[i]);
        }
    }

    /**
     * @dev Checks if a signer (= manager) is approved to manage records for a node
     * @param _node - Namehash of ENS domain
     * @param _signer - Address of signer (= manager)
     */
    function approved(
        bytes32 _node,
        address _signer
    ) public view returns (bool) {
        address _owner = ENS.owner(_node);
        if (isWrapper[_owner]) {
            _owner = iToken(_owner).ownerOf(uint256(_node));
        }
        return _owner == _signer || isApprovedSigner[_owner][_node][_signer];
    }

    /// @dev : Management functions

    /// @dev - Checks for admin privileges
    modifier OnlyDev() {
        if (msg.sender != gateway.owner()) {
            revert NotAuthorised("NOT_DEV");
        }
        _;
    }

    /// @dev - Returns owner of the contract
    function owner() public view returns (address) {
        return gateway.owner();
    }

    /// @dev - Updates ChainID in case of a hardfork
    function updateChainID() public {
        chainID = gateway.uintToString(block.chainid);
    }

    /**
     * @dev Sets fees for ownerhash
     * Note - Set to 0 at launch
     * @param _wei - Fees in WEI per EOA
     */
    function updateOwnerhashFees(uint256 _wei) external OnlyDev {
        ownerhashFees = _wei;
    }

    /**
     * @dev Updates supported interfaces
     * @param _sig - 4-byte interface selector
     * @param _set - State to set for selector
     */
    function updateInterface(bytes4 _sig, bool _set) external OnlyDev {
        if (
            _sig == iCallbackType.signedRecord.selector ||
            _sig == iENSIP10.resolve.selector
        ) {
            revert BadConfig("LOCKED_CALLBACK");
        }
        supportsInterface[_sig] = _set;
        emit InterfaceUpdated(_sig, _set);
    }

    /**
     * @dev Set new Gateway Manager Contract
     * @param _gateway - Address of new Gateway Manager Contract
     */
    function updateGateway(address _gateway) external OnlyDev {
        if (_gateway.code.length == 0) {
            revert BadConfig("BAD_GATEWAY");
        }
        if (msg.sender != iGatewayManager(_gateway).owner()) {
            revert NotAuthorised("BAD_OWNER");
        }
        emit GatewayUpdated(address(gateway), _gateway);
        gateway = iGatewayManager(_gateway);
    }

    /**
     * @dev Add or remove ENS wrapper
     * @param _addr - Address of ENS wrapper
     * @param _set - State to set for new ENS wrapper
     */
    function updateWrapper(address _addr, bool _set) external OnlyDev {
        if (_addr.code.length == 0) {
            revert BadConfig("BAD_WRAPPER");
        }
        isWrapper[_addr] = _set;
        emit UpdatedWrapper(_addr, _set);
    }

    /**
     * @dev Withdraw Ether to owner; to be used for tips or in case some Ether gets locked in the contract
     */
    function withdraw() external {
        payable(gateway.owner()).transfer(address(this).balance);
    }

    /**
     * @dev To be used for tips or in case some fungible tokens get locked in the contract
     * @param _contract - Token contract address
     * @param _balance - Amount to release
     */
    function withdraw(address _contract, uint256 _balance) external {
        iToken(_contract).transferFrom(
            address(this),
            gateway.owner(),
            _balance
        );
    }

    /**
     * @dev To be used for tips or in case some non-fungible tokens get locked in the contract
     * @param _contract - Token contract address
     * @param _token - Token ID to release
     */
    function safeWithdraw(address _contract, uint256 _token) external {
        iToken(_contract).safeTransferFrom(
            address(this),
            gateway.owner(),
            _token
        );
    }
}
