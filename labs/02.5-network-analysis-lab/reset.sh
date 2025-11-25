#!/bin/bash
# ============================================
# Lab 2.5 Reset Script
# ============================================
# Lab 2.5 (Network Analysis & Testing) ei loo
# uusi Docker ressursse. See kasutab Lab 2
# olemasolevat docker-compose stack'i.
#
# See skript kustutab ainult temp faile ja
# selgitab reset protsessi.
# ============================================

echo "============================================"
echo "Lab 2.5: Network Analysis & Testing"
echo "Reset Script"
echo "============================================"
echo ""

echo "MÄRKUS: Lab 2.5 EI LOO UUSI RESSURSSE"
echo ""
echo "Lab 2.5 on TESTING lab, mis kasutab Lab 2 olemasolevat"
echo "docker-compose stack'i analüüsimiseks ja testimiseks."
echo ""
echo "Lab 2.5 ressursid:"
echo "  - Exercises: Juhendid network analysis'iks"
echo "  - Solutions: Bash test skriptid"
echo "  - Temp files: /tmp/test-*.sh, /tmp/*network*.sh"
echo ""
echo "Lab 2.5 EI muuda ega loo:"
echo "  ✗ Docker containers"
echo "  ✗ Docker networks"
echo "  ✗ Docker volumes"
echo "  ✗ Docker images"
echo ""

echo "============================================"
echo "Mida Sa Soovid Teha?"
echo "============================================"
echo ""
echo "1. KUSTUTA TEMP FAILID (soovitatav)"
echo "   - /tmp/test-*.sh"
echo "   - /tmp/monitor-*.sh"
echo "   - /tmp/network-*.sh"
echo ""
echo "2. RESET LAB 2 STACK (kui soovid alustada Lab 2 algusest)"
echo "   - cd ../02-docker-compose-lab"
echo "   - ./reset.sh"
echo ""
echo "3. JÄTA KÕIK NAGU ON (ei kustuta midagi)"
echo ""

read -p "Vali variant (1/2/3) [3]: " choice
choice=${choice:-3}

case $choice in
    1)
        echo ""
        echo "Kusutan temp faile..."
        rm -f /tmp/test-*.sh /tmp/monitor-*.sh /tmp/network-*.sh /tmp/load-*.sh /tmp/stress-*.sh 2>/dev/null
        echo "✓ Temp failid kustutatud"
        echo ""
        echo "Lab 2.5 reset lõpetatud!"
        echo ""
        echo "Lab 2 docker-compose stack töötab endiselt:"
        cd ../02-docker-compose-lab/compose-project 2>/dev/null && docker compose ps 2>/dev/null || echo "  (Lab 2 stack ei tööta)"
        ;;

    2)
        echo ""
        echo "============================================"
        echo "Lab 2 Stack'i Reset"
        echo "============================================"
        echo ""
        echo "Kui soovid resetida Lab 2 stack'i (docker-compose),"
        echo "kasuta Lab 2 reset skripti:"
        echo ""
        echo "  cd ../02-docker-compose-lab"
        echo "  ./reset.sh"
        echo ""
        echo "See kustutab:"
        echo "  - Docker containers (5 teenust)"
        echo "  - Docker networks (3 võrku)"
        echo "  - Docker volumes (2 andmebaasi)"
        echo "  - Docker images (valikuline)"
        echo ""
        read -p "Kas käivitan Lab 2 reset skripti nüüd? (y/N) " run_lab2_reset

        if [[ $run_lab2_reset =~ ^[Yy]$ ]]; then
            echo ""
            if [ -f "../02-docker-compose-lab/reset.sh" ]; then
                cd ../02-docker-compose-lab
                ./reset.sh
            else
                echo "❌ Lab 2 reset.sh ei leitud!"
                echo "   Asukoht: ../02-docker-compose-lab/reset.sh"
            fi
        else
            echo "Tühistatud. Lab 2 stack jäi muutmata."
        fi
        ;;

    3)
        echo ""
        echo "Ei kustutatud midagi."
        echo ""
        echo "Lab 2.5 harjutused ja skriptid on endiselt kasutatavad:"
        echo "  - exercises/ - Harjutuste juhendid"
        echo "  - solutions/ - Valmis test skriptid"
        echo ""
        echo "Lab 2 docker-compose stack töötab endiselt:"
        cd ../02-docker-compose-lab/compose-project 2>/dev/null && docker compose ps 2>/dev/null || echo "  (Lab 2 stack ei tööta)"
        ;;

    *)
        echo ""
        echo "Vigane valik. Ei kustutatud midagi."
        ;;
esac

echo ""
echo "============================================"
echo "Lab 2.5 Reset Valmis"
echo "============================================"
echo ""
echo "JÄRGMISED SAMMUD:"
echo ""
echo "Kui soovid Lab 2.5 uuesti läbi teha:"
echo "  - Harjutused on endiselt olemas: exercises/"
echo "  - Test skriptid on kasutatavad: solutions/"
echo "  - Lab 2 stack peaks töötama: cd ../02-docker-compose-lab/compose-project"
echo ""
echo "Kui soovid jätkata Kubernetes'ega:"
echo "  - Lab 3: cd ../../03-kubernetes-basics-lab"
echo ""
echo "============================================"
