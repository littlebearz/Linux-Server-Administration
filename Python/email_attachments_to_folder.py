import imaplib
import email
import os

svdir = 'c:/downloads'


mail=imaplib.IMAP4('mailserver')
mail.login("username","password")
mail.select("DetReport")

typ, msgs = mail.search(None, '(SUBJECT "Detection")')
msgs = msgs[0].split()

for emailid in msgs:
    resp, data = mail.fetch(emailid, "(RFC822)")
    email_body = data[0][1]
    m = email.message_from_string(email_body)


    if m.get_content_maintype() != 'multipart':
    continue

    for part in m.walk():
        if part.get_content_maintype() == 'multipart':
            continue
        if part.get('Content-Disposition') is None:
            continue

        filename=part.get_filename()
        if filename is not None:
            sv_path = os.path.join(svdir, filename)
            if not os.path.isfile(sv_path):
                print sv_path
                fp = open(sv_path, 'wb')
                fp.write(part.get_payload(decode=True))
                fp.close()
