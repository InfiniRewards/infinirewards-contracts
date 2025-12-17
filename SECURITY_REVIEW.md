# Security Review: SNIP-9 Implementation

**Date**: 2025-12-10
**Reviewer**: Claude Code
**Scope**: SNIP-9 Outside Execution + Merchant Account Integration

## Executive Summary

✅ **Build Status**: All contracts compile successfully
⚠️ **Security Issues Found**: 2 Critical, 1 High, 2 Medium
🔴 **Recommendation**: DO NOT DEPLOY TO PRODUCTION - Critical fixes required

---

## Critical Issues

### 🔴 CRITICAL-1: Signature Does Not Cover Call Data

**File**: `contracts/src/components/outside_execution.cairo:143-160`

**Issue**: The hash computation for signature verification does NOT include the actual calls being executed. This is a critical signature replay vulnerability.

**Current Code**:
```cairo
fn compute_hash(
    self: @ComponentState<TContractState>,
    caller: starknet::ContractAddress,
    nonce: felt252,
    execute_after: u64,
    execute_before: u64,
    calls: Span<Call>,  // ⚠️ RECEIVED BUT NOT USED!
) -> felt252 {
    // Simplified hash - in production use proper SNIP-12 typed data hashing
    core::poseidon::poseidon_hash_span(
        array![
            caller.into(),
            nonce,
            execute_after.into(),
            execute_before.into(),
            // ⚠️ MISSING: calls data!
        ].span()
    )
}
```

**Attack Scenario**:
1. Merchant signs permission to create Points Contract A with params X
2. Attacker intercepts signature
3. Attacker calls `execute_from_outside_v2` with same signature BUT different calls (create Malicious Contract B)
4. Signature validates ✅ because hash doesn't include call data
5. Malicious contract deployed using merchant's signature

**Impact**: Complete bypass of signature authorization - attacker can execute ANY call with a single signature

**Fix Required**:
```cairo
fn compute_hash(
    self: @ComponentState<TContractState>,
    caller: starknet::ContractAddress,
    nonce: felt252,
    execute_after: u64,
    execute_before: u64,
    calls: Span<Call>,
) -> felt252 {
    let mut hash_data = array![
        caller.into(),
        nonce,
        execute_after.into(),
        execute_before.into(),
    ];

    // Hash each call
    for call in calls {
        hash_data.append((*call.to).into());
        hash_data.append(*call.selector);
        // Hash calldata
        for data in *call.calldata {
            hash_data.append(*data);
        }
    };

    core::poseidon::poseidon_hash_span(hash_data.span())
}
```

**SNIP-9 Specification Requirement**: The hash MUST include the complete outside execution structure including all calls. Refer to: https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-9.md

---

### 🔴 CRITICAL-2: Missing Access Control on Contract Management

**File**: `contracts/src/InfiniRewardsMerchantAccount.cairo:85-103`

**Issue**: Functions that modify merchant account state have NO access control. Anyone can call them.

**Vulnerable Functions**:
```cairo
fn add_points_contract(ref self: ContractState, points_contract: ContractAddress) {
    self.points_contracts.push(points_contract);  // ⚠️ NO ACCESS CONTROL
}

fn add_collectible_contract(ref self: ContractState, collectible_contract: ContractAddress) {
    self.collectible_contracts.push(collectible_contract);  // ⚠️ NO ACCESS CONTROL
}

fn add_certificate_contract(ref self: ContractState, certificate_contract: ContractAddress) {
    self.certificate_contracts.push(certificate_contract);  // ⚠️ NO ACCESS CONTROL
}

fn set_metadata(ref self: ContractState, metadata: ByteArray) {
    self.metadata.write(metadata);  // ⚠️ NO ACCESS CONTROL
}
```

**Attack Scenario**:
1. Attacker calls `add_points_contract` with malicious contract address
2. Merchant's account now lists malicious contract as legitimate
3. Users trust the malicious contract because it's listed on merchant account
4. Attacker drains user funds

**Impact**:
- Contract registry pollution
- Phishing attacks via trusted merchant listings
- Metadata manipulation

**Fix Required**:
```cairo
fn add_points_contract(ref self: ContractState, points_contract: ContractAddress) {
    self.account.assert_only_self();  // ✅ Add access control
    self.points_contracts.push(points_contract);
}

fn add_collectible_contract(ref self: ContractState, collectible_contract: ContractAddress) {
    self.account.assert_only_self();  // ✅ Add access control
    self.collectible_contracts.push(collectible_contract);
}

fn add_certificate_contract(ref self: ContractState, certificate_contract: ContractAddress) {
    self.account.assert_only_self();  // ✅ Add access control
    self.certificate_contracts.push(certificate_contract);
}

fn set_metadata(ref self: ContractState, metadata: ByteArray) {
    self.account.assert_only_self();  // ✅ Add access control
    self.metadata.write(metadata);
}
```

**Reference**: The `upgrade` function (line 77-80) correctly uses `self.account.assert_only_self()` - same pattern should be applied.

---

## High Severity Issues

### 🟠 HIGH-1: Non-Standard Hash Function (SNIP-12 Non-Compliance)

**File**: `contracts/src/components/outside_execution.cairo:151-159`

**Issue**: Comment explicitly states "Simplified hash - in production use proper SNIP-12 typed data hashing"

**SNIP-9 Specification**: Requires SNIP-12 typed data hashing for signature verification to ensure:
- Domain separation
- Structured data hashing
- Wallet compatibility
- Replay protection across chains

**Current Implementation**: Uses raw Poseidon hash without SNIP-12 structure

**Impact**:
- Signature replay across different chains/contracts
- Incompatibility with standard wallets
- Unclear message format for users signing

**Fix Required**: Implement proper SNIP-12 typed data hashing structure

**Reference**: https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-12.md

---

## Medium Severity Issues

### 🟡 MEDIUM-1: Redundant Parameter

**File**: `contracts/src/components/outside_execution.cairo:60`

**Issue**: `calls_len: u32` parameter is redundant since `calls.len()` is available

**Code**:
```cairo
fn execute_from_outside_v2(
    ref self: ComponentState<TContractState>,
    caller: starknet::ContractAddress,
    nonce: felt252,
    execute_after: u64,
    execute_before: u64,
    calls_len: u32,  // ⚠️ Redundant - can use calls.len()
    calls: Array<Call>,
    signature: Array<felt252>,
) -> Array<Span<felt252>>
```

**Impact**:
- Potential mismatch between `calls_len` and actual `calls.len()`
- Gas inefficiency
- Code confusion

**Fix**: Remove parameter and use `calls.len()` directly

---

### 🟡 MEDIUM-2: Generic Error Messages

**File**: `contracts/src/components/outside_execution.cairo:70,75,76,79,89,110`

**Issue**: Error messages are too generic for production debugging

**Examples**:
- `'Invalid caller'` - doesn't say what caller was expected
- `'Too early'` / `'Too late'` - doesn't show timestamps
- `'Nonce already used'` - doesn't show the nonce
- `"Call failed"` - no information about which call failed or why

**Impact**: Difficult debugging and poor user experience

**Fix**: Add detailed error messages with context

---

## Positive Findings ✅

1. **Nonce Replay Protection**: Correctly implemented (lines 79-80)
2. **Timestamp Window Validation**: Correctly validates execution window (lines 74-76)
3. **Component Architecture**: Properly structured with clean separation
4. **Event Emission**: Events properly emitted for tracking (lines 122-125)
5. **Build Success**: All contracts compile without errors
6. **Caller Validation**: Multiple caller patterns supported (zero, specific, ANY_CALLER)

---

## Recommendations

### Immediate Actions Required (Before ANY Deployment):

1. **Fix CRITICAL-1**: Implement proper hash computation including call data
2. **Fix CRITICAL-2**: Add `assert_only_self()` to all merchant account management functions
3. **Fix HIGH-1**: Implement SNIP-12 typed data hashing
4. **Testing**: Write comprehensive tests covering:
   - Signature verification with different call data
   - Access control on merchant functions
   - Nonce replay attempts
   - Timestamp boundary conditions
   - Multi-call execution

### Before Production Deployment:

1. **Security Audit**: Engage professional auditor for SNIP-9 implementation
2. **Test Coverage**: Achieve >90% test coverage
3. **Testnet Deployment**: Deploy to testnet and test for 2-4 weeks
4. **Documentation**: Complete SNIP-12 implementation documentation
5. **Fix Medium Issues**: Clean up redundant parameters and improve error messages

---

## Test Checklist

Before deployment, verify:

- [ ] Signature with modified call data fails verification
- [ ] Signature replay with different calls fails
- [ ] Unauthorized calls to `add_*_contract` revert
- [ ] Unauthorized calls to `set_metadata` revert
- [ ] Nonce cannot be reused
- [ ] Calls before `execute_after` revert
- [ ] Calls after `execute_before` revert
- [ ] Multi-call execution works correctly
- [ ] Failed calls properly revert transaction
- [ ] Events are emitted correctly

---

## Risk Assessment

**Current Risk Level**: 🔴 **CRITICAL - DO NOT DEPLOY**

**After Critical Fixes**: 🟡 **MEDIUM - Testnet Only**

**Production Ready**: Requires critical fixes + audit + extensive testing

---

## References

- [SNIP-9 Specification](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-9.md)
- [SNIP-12 Typed Data Hashing](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-12.md)
- [StarkNet Account Abstraction](https://docs.starknet.io/architecture-and-concepts/accounts/introduction/)
- [OpenZeppelin Cairo Contracts](https://github.com/OpenZeppelin/cairo-contracts)
