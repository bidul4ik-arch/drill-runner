import sys, tempfile, os
sys.path.insert(0,os.path.abspath('Server'))
from purchase_ledger import PurchaseLedger, VerifiedPurchase, VerificationUnavailable
with tempfile.TemporaryDirectory() as d:
 db=os.path.join(d,'ledger.sqlite')
 ledger=PurchaseLedger(db)
 try:ledger.process_receipt('a','google','unverified')
 except VerificationUnavailable:pass
 else:raise AssertionError('Unconfigured server must refuse')
 assert ledger.balance('a')==0
 def verify(provider,receipt,account):
  return VerifiedPurchase(provider,receipt,account,'crystals_60',receipt!='pending')
 ledger.verifier=verify
 assert not ledger.process_receipt('a','google','pending')['credited']
 assert ledger.process_receipt('a','google','tx1')['credited']
 assert not ledger.process_receipt('a','google','tx1')['credited']
 assert ledger.balance('a')==60
 ledger.db.close()
 ledger=PurchaseLedger(db,verify)
 assert not ledger.process_receipt('a','google','tx1')['credited']
 assert ledger.purchase_skin('a','aurora')=='purchased'
 assert ledger.purchase_skin('a','aurora')=='owned'
 assert ledger.balance('a')==0
 assert len(ledger.pending_acknowledgements())==1
 ledger.acknowledge('google','tx1')
 assert not ledger.pending_acknowledgements()
 try:ledger.process_receipt('b','google','tx1')
 except ValueError:pass
 else:raise AssertionError('Cross-account reuse must fail')
print('SERVER LEDGER: all checks passed (mock verifier; no store connection)')
