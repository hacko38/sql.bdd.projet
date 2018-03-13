use Pistons
go

----PROCEDURES----
--Procedure Stockée LancerLot
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = LancerLot 100,'R4',@msgRet OUTPUT --Etat Lot, NbPièces à produire, Modele
PRINT @msgRet
PRINT @ret
GO

--Procedure Stockée DemarrerLot
--Passe le lot en "demarré et lui affecte une presse
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = DemarrerLot 1,1001,@msgRet OUTPUT --IdLot, NumPresse
PRINT @msgRet
PRINT @ret
GO

--Procedure Stockée Categorisation
--Recupère les mesures d'une pièce et lui affecte une categorie
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = Categorisation 1,8.02 , 7.92 , 8.05 , 8,@msgRet OUTPUT --idlot, HL,HT,BL,BT, comm
PRINT @msgRet
PRINT @ret
GO

--Procedure Stockée LibererPresse
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = Liberer_presse 1,@msgRet OUTPUT --idlot dont on veut liberer la presse liée
PRINT @msgRet
PRINT @ret
GO

--Procedure Stockée ArretLot
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = ArretLot 2,@msgRet OUTPUT --IdLot, NumPresse
PRINT @msgRet
PRINT @ret
GO

--Sortie des stocks pour tests
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = SortieStock 400,'MOYEN','R4',@msgRet OUTPUT --NbPièces à sortir, Categorie, Modele
PRINT @msgRet
PRINT @ret
GO

--Entrée des stocks pour tests
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = EntreeStock 400,'MOYEN','R4',@msgRet OUTPUT --NbPièces à entrer, Categorie, Modele
PRINT @msgRet
PRINT @ret
GO

--Procedure Ajouter Machine
DECLARE @msgRet varchar(100)
DECLARE @ret int
EXEC @ret = Ajouter_machine 1004,@msgRet OUTPUT --NumPresse
PRINT @msgRet
PRINT @ret
GO

--Procedure Stockée SupprimerMachine
Declare @msgRet varchar(100)
Declare @ret int
exec @ret = Supprimer_Machine 1001, @msgRet OUTPUT 
Print @msgRet
Print @ret
Go

--Procedure Stockée RéhabiliterMachine
Declare @msgRet varchar(100)
Declare @ret int
exec @ret = Rehabiliter_Machine 1004, @msgRet OUTPUT 
Print @msgRet
Print @ret
Go

--Procedure Stockée Ajouter Modèle
Declare @msgRet varchar(200);
Declare @ret int ;
exec @ret =  Ajouter_modele 'Megane' , 21 , @msgRet OUTPUT;
Print @msgRet
Print @ret


--Procedure Stockée SupprimerModèle
Declare @msgRet varchar(100)
Declare @ret int
exec @ret = Supprimer_modele CX8, @msgRet OUTPUT 
Print @msgRet
Print @ret
Go

--Procedure Stockée RéhabiliterModèle
Declare @msgRet varchar(100)
Declare @ret int
exec @ret = Rehabiliter_Modele CX3, @msgRet OUTPUT 
Print @msgRet
Print @ret
Go

--PROCEDURE Getrole
DECLARE @role varchar(50);
EXEC ps_GetRole @role output;
print @role;
GO

--PROCEDURE LOTSSELECT
DECLARE @ret int;
DECLARE @msgret varchar(100);
EXEC @ret = ps_LotsSelect 'R4', @msgret OUTPUT
PRINT @msgret
PRINT @ret
go

--Procedure ModifierSeuil
Declare @msgRet varchar(100)
Declare @ret int
exec @ret = ModifierSeuils 'R4', 'PETIT', 180,  @msgRet OUTPUT 
Print @msgRet
Print @ret
Go


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

--Vue LOT ET PRESSE 
SELECT * FROM VueLotPresse
GO

--Vue TOUS LOTS
SELECT * FROM VueTousLots
GO

----FONCTIONS----
--fonction categoriser
DECLARE @categ varchar(5);
SELECT @categ = dbo.fn_CategoriserPiece(5, 5.09 , 5.09 , 5 , 5.09 )--diambase, HL,HT,BL,BT
PRINT @categ
GO



--exec sp_helpuser hocine


