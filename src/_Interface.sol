// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iERC173 {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;
}

interface iERC3668 {
    error OffchainLookup(
        address _to,
        string[] _gateways,
        bytes _data,
        bytes4 _callbackFunction,
        bytes _extradata
    );

    function resolve(
        bytes memory _name,
        bytes memory _data
    ) external view returns (bytes memory);
}

interface iCcipRead is iERC3668 {
    function __callback(
        bytes calldata _response,
        bytes calldata _extraData
    ) external view returns (bytes memory _result);

    function getSigner(
        string calldata _signRequest,
        bytes calldata _signature
    ) external view returns (address _signer);
}

interface iGatewayManager is iERC173 {
    function randomGateways(
        bytes calldata _recordhash,
        string memory _path,
        uint256 k
    ) external view returns (string[] memory gateways);
    function uintToString(uint256 value) external pure returns (string memory);
    function bytesToHexString(
        bytes calldata _buffer,
        uint256 _start
    ) external pure returns (string memory);
    function bytes32ToHexString(
        bytes32 _buffer
    ) external pure returns (string memory);
    function toChecksumAddress(
        address _addr
    ) external pure returns (string memory);
    function __fallback(
        bytes calldata response,
        bytes calldata extradata
    ) external view returns (bytes memory result);
    function listWeb2Gateways() external view returns (string[] memory list);
    function addWeb2Gateway(string calldata _domain) external;
    function removeWeb2Gateway(uint256 _index) external;
    function replaceWeb2Gateway(
        uint256 _index,
        string calldata _domain
    ) external;
    function listWeb3Gateways() external view returns (string[] memory list);
    function addWeb3Gateway(string calldata _domain) external;
    function removeWeb3Gateway(uint256 _index) external;
    function replaceWeb3Gateway(
        uint256 _index,
        string calldata _domain
    ) external;
}
