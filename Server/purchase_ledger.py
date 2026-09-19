"""Server-side transaction core. Not a deployed payment server.
A trusted provider verifier must be injected; the default rejects all receipts.
Never expose VerifiedPurchase or credit_verified as client request parameters.
"""
from dataclasses import dataclass
import sqlite3

@dataclass(frozen=True)
class VerifiedPurchase:
    provider: str
    transaction_id: str
    account_id: str
    product_id: str
    purchased: bool

class VerificationUnavailable(Exception): pass

def unconfigured_verifier(provider, receipt, account_id):
    raise VerificationUnavailable('Configure Google/Apple verification and account binding first')

class PurchaseLedger:
    def __init__(self, database, verifier=unconfigured_verifier):
        self.db=sqlite3.connect(database)
        self.verifier=verifier
        self.products={'crystals_60':60,'crystals_180':180}
        self.db.executescript('''
        CREATE TABLE IF NOT EXISTS wallets(account_id TEXT PRIMARY KEY, balance INTEGER NOT NULL DEFAULT 0 CHECK(balance>=0));
        CREATE TABLE IF NOT EXISTS transactions(provider TEXT, transaction_id TEXT, account_id TEXT NOT NULL, product_id TEXT NOT NULL, amount INTEGER NOT NULL, acknowledged INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(provider,transaction_id));
        CREATE TABLE IF NOT EXISTS cosmetics(account_id TEXT, skin_id TEXT, PRIMARY KEY(account_id,skin_id));
        ''')
    def process_receipt(self, authenticated_account, provider, opaque_receipt):
        p=self.verifier(provider,opaque_receipt,authenticated_account)
        if not isinstance(p,VerifiedPurchase) or not p.purchased:
            return {'state':'pending','credited':False}
        if p.provider!=provider or p.account_id!=authenticated_account or not p.transaction_id or p.product_id not in self.products:
            raise ValueError('Receipt account/product/provider mismatch')
        with self.db:
            self.db.execute('INSERT OR IGNORE INTO wallets(account_id) VALUES(?)',(authenticated_account,))
            previous=self.db.execute('SELECT account_id FROM transactions WHERE provider=? AND transaction_id=?',(provider,p.transaction_id)).fetchone()
            if previous and previous[0]!=authenticated_account: raise ValueError('Transaction belongs to another account')
            inserted=self.db.execute('INSERT OR IGNORE INTO transactions(provider,transaction_id,account_id,product_id,amount) VALUES(?,?,?,?,?)',(provider,p.transaction_id,authenticated_account,p.product_id,self.products[p.product_id])).rowcount
            if inserted: self.db.execute('UPDATE wallets SET balance=balance+? WHERE account_id=?',(self.products[p.product_id],authenticated_account))
        return {'state':'verified','credited':bool(inserted),'balance':self.balance(authenticated_account),'transaction_id':p.transaction_id}
    def balance(self,account):
        row=self.db.execute('SELECT balance FROM wallets WHERE account_id=?',(account,)).fetchone()
        return row[0] if row else 0
    def purchase_skin(self,account,skin):
        if skin!='aurora': raise ValueError('Unknown premium item')
        with self.db:
            if self.db.execute('SELECT 1 FROM cosmetics WHERE account_id=? AND skin_id=?',(account,skin)).fetchone(): return 'owned'
            changed=self.db.execute('UPDATE wallets SET balance=balance-60 WHERE account_id=? AND balance>=60',(account,)).rowcount
            if not changed:return 'insufficient'
            self.db.execute('INSERT INTO cosmetics VALUES(?,?)',(account,skin))
        return 'purchased'
    def pending_acknowledgements(self):
        return self.db.execute('SELECT provider,transaction_id,account_id FROM transactions WHERE acknowledged=0').fetchall()
    def acknowledge(self,provider,transaction):
        with self.db:self.db.execute('UPDATE transactions SET acknowledged=1 WHERE provider=? AND transaction_id=?',(provider,transaction))
