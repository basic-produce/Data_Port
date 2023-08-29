USE SCM
GO

SELECT [Part Code] as PN, [Short PN] as PN2
FROM MM_Code as MM
JOIN IDN_H2_22 as IDN22
ON [Part Code] = [Short PN]
