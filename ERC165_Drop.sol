// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165_Drop.sol";


abstract contract ERC165 is IERC165_Drop {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual  returns (bool) {
        return interfaceId == type(IERC165_Drop).interfaceId;
    }
}