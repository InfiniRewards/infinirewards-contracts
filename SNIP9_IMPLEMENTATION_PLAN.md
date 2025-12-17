# SNIP-9 Implementation Plan

## Current Status

### Toolchain Updates (✅ Complete)
- **Scarb**: ✅ Upgraded from 2.12.1 → 2.13.1
- **Cairo**: ✅ 2.13.1 (comes with Scarb)
- **Rust**: ✅ Upgraded from 1.88.0 → 1.91.1 (required for edition2024 support)
- **OpenZeppelin**: ✅ Updated from v3.0.0-alpha.1 → v3.0.0-alpha.3
- **snforge_std**: ✅ Updated from v0.49.0 → v0.51.1

### Files Modified
1. ✅ `contracts/src/components/outside_execution.cairo` - Created SNIP-9 component
2. ✅ `contracts/src/components/account.cairo` - Fixed compatibility with OpenZeppelin v3.0.0-alpha.3
3. ✅ `contracts/src/InfiniRewardsMerchantAccount.cairo` - Integrated SNIP-9 component
4. ✅ `contracts/src/lib.cairo` - Added outside_execution module export
5. ✅ `contracts/Scarb.toml` - Updated dependencies
6. ✅ `infinirewards-core/src/core/blockchain/utils/outside-execution.ts` - TypeScript utilities

### Compilation Status
✅ **Contracts compile successfully!** All SNIP-9 implementation is complete and security issues resolved.

### Security Status
✅ **All security issues fixed!**
- ✅ CRITICAL-1: Signature now includes call data (SNIP-12 compliant)
- ✅ CRITICAL-2: Access control added to all merchant functions
- ✅ HIGH-1: SNIP-12 typed data hashing implemented
- ✅ MEDIUM-1: Redundant calls_len parameter removed
- ✅ MEDIUM-2: Error messages improved with "OE:" prefix and context

## How SNIP-9 Works

### Architecture:
```
Master Account (Pays Gas)
    ↓ calls execute_from_outside_v2()
Merchant Account (Caller)
    ↓ validates signature & executes
Factory Contract
    ↓ sees merchant as get_caller_address()
Points Contract Created ✅
```

### Benefits:
- ✅ Master account pays all gas fees
- ✅ Factory sees merchant account as caller
- ✅ No funds transferred to merchant accounts (prevents abuse)
- ✅ Native StarkNet pattern (SNIP-9 standard)
- ✅ No factory contract changes needed

## Next Steps

### 1. ✅ Toolchain Upgrade - COMPLETE
- ✅ Scarb 2.13.1 installed and active
- ✅ Rust 1.91.1 installed
- ✅ All dependencies updated
- ✅ Contracts compile successfully

### 2. Test SNIP-9 Functionality (Next)
Write and run tests to verify:
- `execute_from_outside_v2` accepts valid signatures
- Nonce replay protection works
- Time window validation works
- Call execution succeeds

```bash
cd contracts
scarb test
```

### 3. Deploy Updated Merchant Account
```bash
# Declare new class
starkli declare target/dev/contracts_InfiniRewardsMerchantAccount.contract_class.json

# Update factory with new class hash
# (Requires factory owner/admin action)
```

### 5. Update Backend Code
Use the TypeScript utilities created in:
`infinirewards-core/src/core/blockchain/utils/outside-execution.ts`

For additional program setups:
```typescript
import { executeFromOutside } from '@/core/blockchain/utils/outside-execution';

// Create points contract via SNIP-9
await executeFromOutside(
  merchantAddress,
  merchantPrivateKey,  // From database
  [{
    contractAddress: env.FACTORY_ADDRESS,
    entrypoint: 'create_points_contract',
    calldata: [/* encoded params */]
  }],
  env
);
```

## Alternative Approaches (If SNIP-9 Continues to Have Issues)

### Option A: Factory Update (Simpler, Faster)
Add `create_points_contract_for_merchant(merchant_address, ...)` method to factory
- Pro: Simple, 1 hour to implement
- Con: Requires factory contract update

### Option B: AVNU Paymaster (Easiest)
Use third-party paymaster service
- Pro: No contract changes, works immediately
- Con: Costs per transaction, depends on third party

## References
- [SNIP-9 Specification](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-9.md)
- [Scarb Documentation](https://docs.swmansion.com/scarb/)
- [OpenZeppelin Cairo Contracts](https://github.com/OpenZeppelin/cairo-contracts)
- [Session Keys Guide](https://www.starknet.io/blog/session-keys-on-starknet-unlocking-gasless-secure-transactions/)

## Compilation Issues Encountered & Resolved

### Issue 1: Outdated Toolchain
**Error**: Rust edition2024 feature required but Rust 1.81.0 didn't support it
**Solution**: ✅ Updated Rust from 1.88.0 → 1.91.1, Scarb 2.12.1 → 2.13.1

### Issue 2: OpenZeppelin API Changes
**Error**: `execute_single_call` and `ISRC6` interface not found in expected locations
**Solution**: ✅ Created local `execute_single_call` helper function and updated trait references to use local `AccountComponent::ISRC6`

### Issue 3: Parameter Name Mismatch
**Error**: Interface defined `caller` parameter but implementation used `caller_param`
**Solution**: ✅ Renamed parameter to match interface definition

### Issue 4: Type Inference for Signature Validation
**Error**: Failed to infer type for `is_valid == starknet::VALIDATED`
**Solution**: ✅ Added explicit type annotation: `let is_valid: felt252 = ...`

### Issue 5: snforge_std Compatibility
**Error**: snforge_std v0.49.0 incompatible with Scarb 2.13.1
**Solution**: ✅ Updated snforge_std from v0.49.0 → v0.51.1

## Testing Plan

1. **Unit Tests**: Test outside execution component in isolation
2. **Integration Tests**: Test full flow from master → merchant → factory
3. **Production Test**: Deploy on testnet first, verify gas payment
4. **Migration**: Update existing merchant accounts to new class

## Rollback Plan

If SNIP-9 implementation fails:
1. Revert merchant account contract to original
2. Implement factory update (Option A) instead
3. Deploy updated factory
4. Update backend to use new factory method
5. Total rollback time: ~2-3 hours
