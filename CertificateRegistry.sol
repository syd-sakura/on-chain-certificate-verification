// SPDX-License-Identifier: MIT
// ⚠️ Remix 编译器版本请选 0.8.20（EVM 版本 Shanghai），与 Ganache 完全兼容
pragma solidity ^0.8.20;

/**
 * 证书上链核验系统 · 智能合约
 * 功能：证书哈希上链登记（issue）、链上核验（verify）、撤销（revoke）
 */
contract CertificateRegistry {

    struct Cert {
        bytes32 certHash;   // 证书原文的SHA-256哈希
        address issuer;     // 颁发方地址
        uint256 issuedAt;   // 颁发时间戳
        bool revoked;       // 是否已撤销
    }

    mapping(string => Cert) private certs;

    address public admin;

    event CertIssued(string certId, bytes32 certHash, address issuer, uint256 issuedAt);
    event CertRevoked(string certId, uint256 at);

    constructor() { admin = msg.sender; }

    modifier onlyAdmin() { require(msg.sender == admin, "not admin"); _; }

    /// 签发：把证书编号与SHA-256哈希写入链上（同一编号只能签发一次）
    function issue(string calldata certId, bytes32 certHash) external onlyAdmin {
        require(certs[certId].issuer == address(0), "already issued");
        certs[certId] = Cert(certHash, msg.sender, block.timestamp, false);
        emit CertIssued(certId, certHash, msg.sender, block.timestamp);
    }

    /// 核验：返回 (是否有效, 状态码)  NOT_FOUND / REVOKED / HASH_MISMATCH / VALID
    function verify(string calldata certId, bytes32 certHash)
        external view returns (bool valid, string memory status)
    {
        Cert memory c = certs[certId];
        if (c.issuer == address(0)) return (false, "NOT_FOUND");
        if (c.revoked)              return (false, "REVOKED");
        if (c.certHash != certHash) return (false, "HASH_MISMATCH");
        return (true, "VALID");
    }

    /// 撤销：管理员宣布某证书作废
    function revoke(string calldata certId) external onlyAdmin {
        require(certs[certId].issuer != address(0), "not found");
        certs[certId].revoked = true;
        emit CertRevoked(certId, block.timestamp);
    }
}
