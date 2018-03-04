use Pistons
go

----PROCEDURES----
--Procedure Stock�e LancerLot
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = LancerLot 1,100,'R4',@msgRet OUTPUT --Etat Lot, NbPi�ces � produire, Modele
PRINT @msgRet
PRINT @ret
GO

--Procedure Stock�e DemarrerLot
--Passe le lot en "demarr� et lui affecte une presse
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = DemarrerLot 1,1001,@msgRet OUTPUT --IdLot, NumPresse
PRINT @msgRet
PRINT @ret
GO

--Procedure Stock�e Categorisation
--Recup�re les mesures d'une pi�ce et lui affecte une categorie
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = Categorisation 1,8.02 , 7.92 , 8.05 , 8,@msgRet OUTPUT --idlot, HL,HT,BL,BT
PRINT @msgRet
PRINT @ret
GO

--Procedure Stock�e LibererPresse
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = Liberer_presse 1,@msgRet OUTPUT --idlot dont on veut liberer la presse li�e
PRINT @msgRet
PRINT @ret
GO

--Procedure Stock�e ArretLot
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = ArretLot 1,@msgRet OUTPUT --IdLot, NumPresse
PRINT @msgRet
PRINT @ret
GO

--Sortie des stocks pour tests
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = SortieStock 400,'MOYEN','R4',@msgRet OUTPUT --NbPi�ces � sortir, Categorie, Modele
PRINT @msgRet
PRINT @ret
GO

--Entr�e des stocks pour tests
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = EntreeStock 400,'MOYEN','R4',@msgRet OUTPUT --NbPi�ces � sortir, Categorie, Modele
PRINT @msgRet
PRINT @ret
GO

--Procedure Ajouter Machine
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = Ajouter_machine 1003,@msgRet OUTPUT --NumPresse
PRINT @msgRet
PRINT @ret
GO

----VUES----
--Vue Stock
SELECT * FROM VueStocksCategorie
GO
--Vue Rupture
SELECT * FROM VueRuptureStock
GO
--Vue Rupture
SELECT * FROM VueEtatPresse
GO

----FONCTIONS----
--fonction categoriser
DECLARE @categ varchar(5);
SELECT @categ = dbo.fn_CategoriserPiece(5, 5.09 , 5.09 , 5 , 5.09 )--diambase, HL,HT,BL,BT
PRINT @categ
GO
