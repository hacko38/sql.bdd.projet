use Pistons
go

DROP TRIGGER AjoutPiece
DROP TRIGGER TriggerCumul
go

DROP FUNCTION fn_CategoriserPiece
DROP FUNCTION fn_GetRole
go

DROP PROCEDURE Ajouter_modele
DROP PROCEDURE Ajouter_machine
DROP PROCEDURE CreerCumul
DROP PROCEDURE LancerLot
DROP PROCEDURE SortieStock
DROP PROCEDURE EntreeStock
DROP PROCEDURE DemarrerLot
DROP PROCEDURE Categorisation
DROP PROCEDURE Liberer_presse
DROP PROCEDURE ArretLot
DROP PROCEDURE Supprimer_machine
DROP PROCEDURE Rehabiliter_machine
DROP PROCEDURE Supprimer_modele
DROP PROCEDURE Rehabiliter_Modele
DROP PROCEDURE ps_GetRole
go

DROP VIEW VueStocksCategorie
DROP VIEW VueRuptureStock
DROP VIEW VueEtatPresse
DROP VIEW VueLotPresse
DROP VIEW VueTousLots
go

DROP USER uresp_appli 
DROP USER uresp_atelier1
DROP USER uresp_atelier2	
DROP USER uresp_production1
DROP USER uresp_production2
DROP USER ucontroleur1 
DROP USER ucontroleur2 
DROP USER ucontroleur3
DROP USER umagasinier1 
DROP USER umagasinier2 
DROP USER umagasinier3 
DROP USER uresp_qualit�1
DROP USER uresp_qualit�2
go

/*
DROP LOGIN resp_appli
DROP LOGIN resp_atelier1
DROP LOGIN resp_atelier2
DROP LOGIN resp_production1
DROP LOGIN resp_production2
DROP LOGIN controleur1 
DROP LOGIN controleur2
DROP LOGIN controleur3
DROP LOGIN magasinier1
DROP LOGIN magasinier2
DROP LOGIN magasinier3
DROP LOGIN resp_qualit�1
DROP LOGIN resp_qualit�2
go
*/

DROP ROLE CONTROLEUR
DROP ROLE RESP_ATELIER
DROP ROLE RESP_PRODUCTION
DROP ROLE RESP_QUALITE
DROP ROLE RESP_APPLI
DROP ROLE MAGASINIER
go

DROP TABLE CUMUL

DROP TABLE PIECE
go

DROP TABLE STOCK

DROP TABLE LOT
go

DROP TABLE ETAT_LOT
go

DROP TABLE MODELE

DROP TABLE CATEGORIE

DROP TABLE MACHINE
go

DROP TYPE TypeDiametre

DROP TYPE TypeCategorie

DROP TYPE TypeModele

DROP TYPE TypePieceLot
go

