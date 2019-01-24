%dw 2.0
import dw::core
var customer=payload.body.GetCustomerResponse.Customer
var contactMechanisms=customer.ContactMechanism
var primaryAddressConsents=(
		(
			(contactMechanisms.AddressList.*Address default []) 
			filter ($.PurposeList..Description contains "Identifying")
		).PurposeList.*Purpose.Code default []
)
var primaryPhoneConsents=(
	(
		(contactMechanisms.PhoneList.*Phone default []) 
		filter ($.PurposeList..Description contains "Identifying")
	).PurposeList.*Purpose.Description default []
)
var primaryEmail=(
	(
		(contactMechanisms.EmailList.*Email default []) 
		filter ($.PurposeList..Description contains "Identifying")
	)[0] default null
)
var emailsAllowed=(primaryEmail.MarketingAllowed == "Y")
var postAllowed=(
	(primaryEmail.PurposeList.*Purpose.Description default []) 
	contains "Mailing"
)
---
{
	consents: [
		{
			consentType: "accaMarketing",
			consent: primaryAddressConsents contains "ACCA_ALLOW_MKTING"
		},
		{
			consentType: "ACCA_MAIL_TBC",
			consent: primaryAddressConsents contains "ACCA_MAIL"
		},
		{
			consentType: "thirdPartyMarketing",
			consent: primaryAddressConsents contains "ACCA_ALLOW_THIRD_MKT"
		},
		{
			consentType: "smsResultConsent",
			consent: primaryPhoneConsents contains "Exam Results"
		},
		{
			consentType: "smsGeneralConsnet",
			consent: primaryPhoneConsents contains "Allow SMS"
		},
		{
			consentType: "communicationPreference",
			consentLevel: (
				// All Correspondence by Paper where possible
				if ( (not emailsAllowed) and postAllowed) 1
				// All Correspondence by Email where possible
				else if (emailsAllowed and (not postAllowed)) 2
				// Publications and updates by Email, Account Correspondence by Paper where possible
				else if (emailsAllowed and postAllowed) 3
				else null	
			),
			consentLevelDescription: (
				if ( (not emailsAllowed) and postAllowed) "I would like to receive all correspondence from ACCA by paper where possible"
				else if (emailsAllowed and (not postAllowed)) "I would like to receive all correspondence from ACCA by e-communications where possible"
				else if (emailsAllowed and postAllowed) "I would like to receive publications and updates by e-communications but still receive my account correspondence by paper"
				else null	
			)
		} 
	]
}