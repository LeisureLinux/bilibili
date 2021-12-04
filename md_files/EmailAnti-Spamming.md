#### [建设自己的邮件系统 AS/AV](https://tech.yj777.cn/%E7%94%A8-postfixdovecot-%E5%9C%A8-centos7-%E4%B8%8A%E5%BF%AB%E9%80%9F%E6%90%AD%E5%BB%BA%E8%87%AA%E5%B7%B1%E7%9A%84%E5%AE%89%E5%85%A8%E9%82%AE%E4%BB%B6%E6%9C%8D%E5%8A%A1%E5%99%A8/)

- 邮件系统的核心组件： apt/yum install postfix dovecot
- 反垃圾邮件的组件

  - 服务： spamassassin + spamass-milter
  - 示例邮件头(部分)
    > Subject: =?utf-8?B?55Sz6ZO25LiH5Zu9X+ihjOS4mueCueivhF/pmYjng6jov5xf?=
    > =?utf-8?B?T21pY3JvbuWPmOW8guagquiiq+WIl+S4ulZPQ+S6i+S7tueCueivhF/v?=
    > =?utf-8?B?vIrvvIrvvIpf?=
    > Content-Type: multipart/mixed;
    > boundary=--boundary_592_fb99ee02-2f7a-47dc-b19e-2467081e87ca
    > X-Spam-Status: No, score=0.0 required=12.0 tests=RCVD_IN_SORBS_DUL,
    > SPF_HELO_NONE,SPF_PASS autolearn=no autolearn_force=no version=3.4.0
    > X-Spam-Checker-Version: SpamAssassin 3.4.0 (2014-02-07) on mailhost-01
    > X-Virus-Scanned: clamav-milter 0.103.4 at mailhost-01
    > X-Virus-Status: Clean
  - /var/log/maillog 的日志示例（部分）
    > Nov 28 18:47:06 mailhost-01 postfix/smtpd[29384]: connect from unknown[182.84.144.255]
    > Nov 28 18:47:07 mailhost-01 postfix/smtpd[29384]: 1692760C5: client=unknown[182.84.144.255]
    > Nov 28 18:47:07 mailhost-01 postfix/cleanup[29394]: 1692760C5: message-id=<>
    > Nov 28 18:47:07 mailhost-01 spamd[25529]: spamd: got connection over /run/spamd.sock
    > Nov 28 18:47:07 mailhost-01 spamd[25529]: spamd: setuid to postfix succeeded
    > Nov 28 18:47:07 mailhost-01 spamd[25529]: spamd: creating default_prefs: /var/spool/postfix/.spamassassin/user_prefs
    > Nov 28 18:47:07 mailhost-01 spamd[25529]: config: created user preferences file: /var/spool/postfix/.spamassassin/user_prefs
    > Nov 28 18:47:07 mailhost-01 spamd[25529]: spamd: processing message (unknown) for postfix:89
    > Nov 28 18:47:18 mailhost-01 spamd[25529]: spamd: identified spam (27.6/12.0) for postfix:89 in 10.2 seconds, 604 bytes.
    > Nov 28 18:47:18 mailhost-01 spamd[25529]: spamd: result: Y 27 - DOS_OE_TO_MX,FORGED_MUA_OUTLOOK,
    > FREEMAIL_FROM,FSL_HELO_FAKE,MISSING_MID,NO_RDNS_DOTCOM_HELO,PDS_HP_HELO_NORDNS,RCVD_IN_BL_SPAMCOP_NET,
    > RCVD_IN_PBL,RCVD_IN_SBL_CSS,RCVD_IN_XBL,RDNS_NONE,SPOOFED_FREEMAIL,SPOOFED_FREEMAIL_NO_RDNS,
    > TO_NO_BRKTS_MSFT,TVD_SPACE_ENCODED
    > scantime=10.2,size=604,user=postfix,uid=89,
    > required_score=12.0,
    > rhost=localhost,raddr=127.0.0.1,rport=/run/spamd.sock,mid=(unknown),autolearn=no autolearn_force=no
    > Nov 28 18:47:18 mailhost-01 postfix/cleanup[29394]: 1692760C5:
    > milter-reject: END-OF-MESSAGE from unknown[182.84.144.255]:
    > 5.7.1 Dude, Don't Spam!;
    > from=<dfatjgvhb@hotmail.com> to=<user@mymailhost.com> proto=ESMTP helo=<hotmail.com>
    > Nov 28 18:47:18 mailhost-01 spamd[25525]: prefork: child states: II
    > Nov 28 18:47:18 mailhost-01 postfix/smtpd[29384]: disconnect from unknown[182.84.144.255]
    > Nov 28 18:50:38 mailhost-01 postfix/anvil[29391]: statistics: max connection rate 1/60s for (smtp:182.84.144.255) at Nov 28 18:47:06
    > Nov 28 18:50:38 mailhost-01 postfix/anvil[29391]: statistics: max connection count 1 for (smtp:182.84.144.255) at Nov 28 18:47:06
    > Nov 28 18:50:38 mailhost-01 postfix/anvil[29391]: statistics: max cache size 1 at Nov 28 18:47:06
  - 实现方法 /etc/sysconfig/spamass-milter
    > SOCKET=/run/spamass-milter/postfix.sock
    > EXTRA_FLAGS="-a -g postfix -r 11 -I -i 127.0.0.1 -R \"Dude, Don't Spam!\""
  - Spam Score 的配置： /etc/mail/spamassassin/local.cf

    > required*hits 12.00
    > rewrite_header Subject \*\*\*\*SPAM(\_SCORE*)\*\*\*\*
    > report*safe 0
    > use_bayes 1
    > bayes_auto_learn 1
    > bayes_auto_learn_threshold_nonspam -1.7
    > bayes_auto_learn_threshold_spam 5.00
    > skip_rbl_checks 0
    > use_razor2 1
    > use_pyzor 1
    > pyzor_options --homedir /etc/mail/spamassassin/.pyzor
    > blacklist_from *@sohu.com _@mailfb.com
    > whitelist_from 10000@qq.com
    > ok_locales zh en
    > score HEADER_8BITS 0
    > score HTML_COMMENT_8BITS 0
    > score SUBJ_FULL_OF_8BITS 0
    > score SPF_FAIL 10.000
    > header **BY_BOSSEDM Received =~ /by edm01.bossedm.com/
    > score **BY_BOSSEDM 10

  - 需要注意的用户/权限问题 # grep postfix /etc/group
    > mail:x:12:postfix
    > postfix:x:89:sa-milt
    > virusgroup:x:775:clamupdate,clamilt,clamscan,postfix
    > sa-milt:x:773:postfix
    > clamilt:x:772:postfix

- 反病毒的组件
  - clamav-milter
  - clamd@scan
