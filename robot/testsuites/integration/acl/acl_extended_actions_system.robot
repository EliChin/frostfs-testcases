*** Settings ***
Variables    common.py

Library     Collections
Library     neofs.py
Library     neofs_verbs.py
Library     payment_neogo.py
Library     acl.py

Resource    common_steps_acl_extended.robot
Resource    payment_operations.robot
Resource    setup_teardown.robot
Resource    eacl_tables.robot

*** Variables ***
&{USER_HEADER} =        key1=1      key2=abc
&{USER_HEADER_DEL} =    key1=del    key2=del
&{ANOTHER_USER_HEADER} =        key1=oth    key2=oth

*** Test cases ***
Extended ACL Operations
    [Documentation]         Testcase to validate NeoFS operations with extended ACL.
    [Tags]                  ACL  eACL
    [Timeout]               20 min

    [Setup]                 Setup

    ${WALLET}   ${ADDR}     ${USER_KEY} =   Prepare Wallet And Deposit

                            Log    Check extended ACL with simple object
                            Generate files    ${SIMPLE_OBJ_SIZE}
                            Check eACL Deny and Allow All System    ${USER_KEY}    ${FILE_S}

                            Log    Check extended ACL with complex object
                            Generate files    ${COMPLEX_OBJ_SIZE}
                            Check eACL Deny and Allow All System    ${USER_KEY}    ${FILE_S}

    [Teardown]              Teardown    acl_extended_actions_system


*** Keywords ***

Check eACL Deny and Allow All System
    [Arguments]     ${USER_KEY}      ${FILE_S}

    ${CID} =            Create Container Public     ${USER_KEY}

    ${S_OID_USER} =     Put object      ${USER_KEY}    ${FILE_S}    ${CID}    user_headers=${USER_HEADER}
    ${D_OID_USER_S} =   Put object      ${USER_KEY}    ${FILE_S}    ${CID}    user_headers=${USER_HEADER_DEL}
    ${D_OID_USER_SN} =  Put object      ${USER_KEY}    ${FILE_S}    ${CID}    user_headers=${USER_HEADER_DEL}

    @{S_OBJ_H} =	Create List	    ${S_OID_USER}

                        Put object      ${NEOFS_IR_WIF}    ${FILE_S}    ${CID}    user_headers=${ANOTHER_USER_HEADER}
                        Put object      ${NEOFS_SN_WIF}    ${FILE_S}    ${CID}    user_headers=${ANOTHER_USER_HEADER}

                        Get object    ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    local_file_eacl
                        Get object    ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    local_file_eacl

                        Search object        ${NEOFS_IR_WIF}    ${CID}    ${EMPTY}    ${EMPTY}    ${USER_HEADER}    ${S_OBJ_H}
                        Search object        ${NEOFS_SN_WIF}    ${CID}    ${EMPTY}    ${EMPTY}    ${USER_HEADER}    ${S_OBJ_H}

                        Head object          ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}
                        Head object          ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}

                        Run Keyword And Expect Error    *
                        ...    Get Range            ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}    s_get_range    ${EMPTY}    0:256
                        Run Keyword And Expect Error    *
                        ...    Get Range            ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}    s_get_range    ${EMPTY}    0:256

                        Get Range Hash       ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    0:256
                        Get Range Hash       ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    0:256

                        Run Keyword And Expect Error    *
                        ...    Delete object        ${NEOFS_IR_WIF}    ${CID}    ${D_OID_USER_S}
                        Run Keyword And Expect Error    *
                        ...    Delete object        ${NEOFS_SN_WIF}    ${CID}    ${D_OID_USER_SN}

                        Set eACL             ${USER_KEY}     ${CID}       ${EACL_DENY_ALL_SYSTEM}

                        # The current ACL cache lifetime is 30 sec
                        Sleep    ${NEOFS_CONTRACT_CACHE_TIMEOUT}

                        Run Keyword And Expect Error    *
                        ...  Put object        ${NEOFS_IR_WIF}    ${FILE_S}    ${CID}    user_headers=${ANOTHER_USER_HEADER}
                        Run Keyword And Expect Error    *
                        ...  Put object        ${NEOFS_SN_WIF}    ${FILE_S}    ${CID}    user_headers=${ANOTHER_USER_HEADER}

                        Run Keyword And Expect Error    *
                        ...  Get object      ${NEOFS_IR_WIF}      ${CID}    ${S_OID_USER}    ${EMPTY}    local_file_eacl
                        Run Keyword And Expect Error    *
                        ...  Get object      ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    local_file_eacl

                        Run Keyword And Expect Error    *
                        ...  Search object              ${NEOFS_IR_WIF}    ${CID}    ${EMPTY}    ${EMPTY}    ${USER_HEADER}    ${S_OBJ_H}
                        Run Keyword And Expect Error    *
                        ...  Search object              ${NEOFS_SN_WIF}    ${CID}    ${EMPTY}    ${EMPTY}    ${USER_HEADER}    ${S_OBJ_H}


                        Run Keyword And Expect Error        *
                        ...  Head object                ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}
                        Run Keyword And Expect Error        *
                        ...  Head object                ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}

                        Run Keyword And Expect Error        *
                        ...  Get Range                  ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}    s_get_range    ${EMPTY}    0:256
                        Run Keyword And Expect Error        *
                        ...  Get Range                  ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}    s_get_range    ${EMPTY}    0:256


                        Run Keyword And Expect Error        *
                        ...  Get Range Hash             ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    0:256
                        Run Keyword And Expect Error        *
                        ...  Get Range Hash             ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    0:256


                        Run Keyword And Expect Error        *
                        ...  Delete object              ${NEOFS_IR_WIF}    ${CID}        ${S_OID_USER}
                        Run Keyword And Expect Error        *
                        ...  Delete object              ${NEOFS_SN_WIF}    ${CID}        ${S_OID_USER}


                        Set eACL                        ${USER_KEY}     ${CID}        ${EACL_ALLOW_ALL_SYSTEM}

                        # The current ACL cache lifetime is 30 sec
                        Sleep    ${NEOFS_CONTRACT_CACHE_TIMEOUT}

                        Delete object        ${USER_KEY}    ${CID}    ${D_OID_USER_S}
                        Delete object        ${USER_KEY}    ${CID}    ${D_OID_USER_SN}

    ${D_OID_USER_S} =   Put object     ${USER_KEY}     ${FILE_S}    ${CID}    user_headers=${USER_HEADER_DEL}
    ${D_OID_USER_SN} =  Put object     ${USER_KEY}     ${FILE_S}    ${CID}    user_headers=${USER_HEADER_DEL}

                        Put object     ${NEOFS_IR_WIF}    ${FILE_S}     ${CID}    user_headers=${ANOTHER_USER_HEADER}
                        Put object     ${NEOFS_SN_WIF}    ${FILE_S}     ${CID}    user_headers=${ANOTHER_USER_HEADER}

                        Get object       ${NEOFS_IR_WIF}    ${CID}        ${S_OID_USER}      ${EMPTY}    local_file_eacl
                        Get object       ${NEOFS_SN_WIF}    ${CID}        ${S_OID_USER}      ${EMPTY}    local_file_eacl

                        Search object        ${NEOFS_IR_WIF}    ${CID}    ${EMPTY}        ${EMPTY}     ${USER_HEADER}       ${S_OBJ_H}
                        Search object        ${NEOFS_SN_WIF}    ${CID}    ${EMPTY}        ${EMPTY}     ${USER_HEADER}       ${S_OBJ_H}

                        Head object          ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}
                        Head object          ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}

                        Run Keyword And Expect Error        *
                        ...  Get Range            ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}    s_get_range      ${EMPTY}    0:256
                        Run Keyword And Expect Error        *
                        ...  Get Range            ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}    s_get_range      ${EMPTY}    0:256

                        Get Range Hash       ${NEOFS_IR_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    0:256
                        Get Range Hash       ${NEOFS_SN_WIF}    ${CID}    ${S_OID_USER}    ${EMPTY}    0:256

                        Run Keyword And Expect Error        *
                        ...  Delete object        ${NEOFS_IR_WIF}    ${CID}    ${D_OID_USER_S}
                        Run Keyword And Expect Error        *
                        ...  Delete object        ${NEOFS_SN_WIF}    ${CID}    ${D_OID_USER_SN}
