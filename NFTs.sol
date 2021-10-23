pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftEjm is ERC721Enumerable, Ownable {
    string public baseURI;
    mapping(uint256 => string) private _hashIPFS;
    uint256[] codigos;
    uint256[] codigotitulos;
    //address[] alumanosmatriculados;
    mapping (uint256 => Asignatura) public asignaturas;
    mapping (uint256 => Titulo) public titulos;


    struct Asignatura{
        uint256 codigo;
        uint32 creditos;
        address[] alumnos;
        uint256[] DNI;
    }
    struct Titulo{
        uint256 codigotitulo;
        uint256[] requeridos;
    }
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        baseURI = "https://ipfs.io/ipfs/";
    }
    
    function addAsignatura(uint256 _co,uint32 _creditos)public onlyOwner{
        codigos.push(_co);
        asignaturas[_co].codigo = _co;
        asignaturas[_co].creditos = _creditos; 
      // asignaturas.push(Asignatura(_co, _creditos));
       
    }
    function matricularalumno(uint256 _asig, address _alumno, uint256 _DNI)public onlyOwner{
        asignaturas[_asig].alumnos.push(_alumno);
        asignaturas[_asig].DNI.push(_DNI) ;
    }
    function getAsignatura(uint256 _co) external view returns(uint256 codigo,uint32 creditos, address[] memory alumnos){
        codigo = asignaturas[_co].codigo;
        creditos = asignaturas[_co].creditos;
        alumnos = asignaturas[_co].alumnos;
    }   
    function createTitulo(uint256 _cot, uint256[] memory _identificadores) public  onlyOwner{
        codigotitulos.push(_cot);
        titulos[_cot].codigotitulo = _cot;
        titulos[_cot].requeridos = _identificadores;
    }
    function getTitulo(uint256 _cot) external view returns(uint256 codigotitulo, uint256[] memory requeridos){
        codigotitulo = titulos[_cot].codigotitulo;
        requeridos = titulos[_cot].requeridos;

    }
    function mintAsignatura(address _to, string[] memory _hashes, uint256[] memory _nota, uint256[] memory _porcentaje, Asignatura memory _as) public onlyOwner {
        //uint256 ident = _ident;
        uint32 existe= 0;
        uint256 code= _as.codigo;
        uint256 media = 0;
        for (uint256 z = 0; z < codigos.length; z++) {
          if( codigos[z]==code){
              existe++;
          }
        }
        require(existe==1,"Esta asignatura no existe");
        address[] matriculados = _as.alumnos;
        uint256[] dnimatriculados = _as.DNI;
        uint8 matriculado = 0;
        uint256 index = 0;
        for( uint256 a = 0; a< matriculados.length,a++){
            if(_to == matriculados[a]){
                matriculado++;
                index=a;
            } 
        }
        require (matriculado == 1, "La dirección no corresponde con ningun alumno matriculado");

        for (uint256 j = 0; j < _nota.length; j++) {
            media=media+_nota[j]*_porcentaje[j]/100;
        }  
        require(media>5, "Nota insuficiente");
        //calcular tokenID
        uint256 dni= _as.DNI[index];
        dni=dni*100000000;
        uint256 idtoken = dni+code; 
        for (uint256 i = 0; i < _hashes.length; i++) {
            _safeMint(_to, idtoken + i);
            _hashIPFS[idtoken + i] = _hashes[i];
        }
    }
    function mintTitulo(address _to, string[] memory _hashes, Titulo memory _tit, uint256 _DNI) public onlyOwner {
        //uint256 supply = totalSupply();
        uint256[] _code = _tit.requeridos;
        uint256 contador = 0;
        uint256[] _tokenId;
        uint256 formato= _DNI*100000000;
        for (uint256 c = 0; c < _code.length;c++ ){
        _tokenId[c]=formato+_code[c];
        }
        uint256[] memory tokensalumno=walletOfOwner(_to);
        for (uint256 j = 0; j < _tokenId.length; j++){
         require(
            _exists(_tokenId[j]),
            "Ese token no existe"
        );
       for (uint256 k = 0; k < tokensalumno.length; k++){
           if(tokensalumno[k]==_tokenId[j]){
               contador++;
           }
        
       }
        }
         require(
            contador==_tokenId.length,
            "No ha aprobado todas las asignaturas"
        );

        for (uint256 i = 0; i < _hashes.length; i++) {
            _safeMint(_to, _DNI + i);
            _hashIPFS[_DNI + i] = _hashes[i];
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            (bytes(currentBaseURI).length > 0 &&
                bytes(_hashIPFS[tokenId]).length > 0)
                ? string(abi.encodePacked(currentBaseURI, _hashIPFS[tokenId]))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
}